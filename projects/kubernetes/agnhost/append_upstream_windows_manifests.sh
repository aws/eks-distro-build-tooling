#!/usr/bin/env bash
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail
set -x

IMAGE="$1"
UPSTREAM_IMAGE="$2"
METADATA_FILE="$3"

IMAGE_REPO_NAME="${IMAGE%:*}"
UPSTREAM_REPO_NAME="${UPSTREAM_IMAGE%:*}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

LINUX_INDEX="${IMAGE_REPO_NAME}@$(jq -r '."containerimage.descriptor".digest' "${METADATA_FILE}")"

docker buildx imagetools inspect --raw "${UPSTREAM_IMAGE}" > "${WORK_DIR}/upstream-index.json"
docker buildx imagetools inspect --raw "${LINUX_INDEX}" > "${WORK_DIR}/linux-index.json"

WINDOWS_REFS=$(jq -r --arg repo "${UPSTREAM_REPO_NAME}" '.manifests[] | select(.platform.os == "windows") | "\($repo)@\(.digest)"' "${WORK_DIR}/upstream-index.json")
if [ -z "${WINDOWS_REFS}" ]; then
  echo "No windows manifests found in ${UPSTREAM_IMAGE}"
  exit 1
fi

# Copy the unchanged upstream windows manifests into the target repo.
docker buildx imagetools create -t "${IMAGE}" "${LINUX_INDEX}" ${WINDOWS_REFS}

# buildx drops os.version for single-manifest sources, so rewrite the index from descriptors that carry the upstream platform.
# mediaType is removed because buildx segfaults when it is set, matching eks-distro-base/create_windows_manifest.sh.
{
  jq -c '.manifests[] | select(.platform.os == "linux") | {digest, size, platform}' "${WORK_DIR}/linux-index.json"
  jq -c '.manifests[] | select(.platform.os == "windows") | {digest, size, platform}' "${WORK_DIR}/upstream-index.json"
} | split -l 1 - "${WORK_DIR}/descriptor-"

DESCRIPTOR_ARGS=()
for descriptor in "${WORK_DIR}"/descriptor-*; do
  DESCRIPTOR_ARGS+=(-f "${descriptor}")
done

# Capture the digest of the index we push: public.ecr.aws serves tag reads from a
# cache that lags a push by a minute or more (the first runs read back the
# Linux-only index, or a Windows child manifest, long after the final index was
# pushed), so verification must go by digest, which cannot be stale.
CREATE_LOG="${WORK_DIR}/create.log"
docker buildx imagetools create -t "${IMAGE}" "${DESCRIPTOR_ARGS[@]}" 2>&1 | tee "${CREATE_LOG}"
FINAL_DIGEST=$(grep -oE 'pushing sha256:[0-9a-f]{64} to ' "${CREATE_LOG}" | tail -1 | awk '{print $2}')
if [ -z "${FINAL_DIGEST}" ]; then
  echo "Could not determine the pushed index digest from imagetools output"
  exit 1
fi
echo "Pushed ${IMAGE} as ${FINAL_DIGEST}"

EXPECTED_WINDOWS=$(jq -c '[.manifests[] | select(.platform.os == "windows") | {digest, platform}] | sort_by(.digest)' "${WORK_DIR}/upstream-index.json")
ACTUAL_WINDOWS=""
for attempt in 1 2 3 4 5 6; do
  ACTUAL_WINDOWS=$(docker buildx imagetools inspect --raw "${IMAGE_REPO_NAME}@${FINAL_DIGEST}" 2>/dev/null \
    | jq -c '[.manifests[]? | select(.platform.os == "windows") | {digest, platform}] | sort_by(.digest)' 2>/dev/null || true)
  if [ "${EXPECTED_WINDOWS}" = "${ACTUAL_WINDOWS}" ]; then
    echo "Windows manifests in ${IMAGE_REPO_NAME}@${FINAL_DIGEST} match ${UPSTREAM_IMAGE}"
    docker buildx imagetools inspect "${IMAGE_REPO_NAME}@${FINAL_DIGEST}"
    exit 0
  fi
  echo "attempt ${attempt}: pushed index not readable yet; got: ${ACTUAL_WINDOWS:-<none>}"
  sleep 10
done

echo "Windows manifests in ${IMAGE_REPO_NAME}@${FINAL_DIGEST} do not match ${UPSTREAM_IMAGE}"
docker buildx imagetools inspect --raw "${IMAGE_REPO_NAME}@${FINAL_DIGEST}" || true
exit 1
