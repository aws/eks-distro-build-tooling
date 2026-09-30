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

# Usage: tag_image_children.sh <repo>:<build-tag>[,<repo>:<tag>...]
# Only the first tag is applied to child manifests, so it must be unique to the build.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_ROOT}/common.sh"

IMAGE="${1%%,*}"
REPO="${IMAGE%:*}"
TAG="${IMAGE##*:}"

INDEX_FILE=$(mktemp)
trap 'rm -f "${INDEX_FILE}"' EXIT
retry oras manifest fetch --output "${INDEX_FILE}" "${IMAGE}"

if ! jq -e 'has("manifests")' "${INDEX_FILE}" > /dev/null; then
    echo "${IMAGE} is a single manifest, no child images to tag"
    exit 0
fi

declare -A SUFFIX_FOR_DIGEST
declare -A USED_SUFFIXES

PLATFORMS=$(jq -r '.manifests[] | select(.annotations["vnd.docker.reference.type"] != "attestation-manifest") | "\(.digest) \(.platform.os // "")_\(.platform.architecture // "")"' "${INDEX_FILE}")
while read -r digest suffix; do
    if [[ "${suffix}" == _* ]] || [[ "${suffix}" == *_ ]]; then
        echo "${REPO}@${digest} has no os or architecture in ${IMAGE}"
        exit 1
    fi
    if [ -n "${USED_SUFFIXES[$suffix]:-}" ]; then
        echo "${IMAGE} has more than one manifest for ${suffix}"
        exit 1
    fi
    USED_SUFFIXES[$suffix]=1
    SUFFIX_FOR_DIGEST[$digest]=$suffix
done <<< "${PLATFORMS}"

ATTESTATIONS=$(jq -r '.manifests[] | select(.annotations["vnd.docker.reference.type"] == "attestation-manifest") | "\(.digest) \(.annotations["vnd.docker.reference.digest"])"' "${INDEX_FILE}")
if [ -n "${ATTESTATIONS}" ]; then
    while read -r digest subject; do
        if [ -z "${SUFFIX_FOR_DIGEST[$subject]:-}" ]; then
            echo "Attestation ${REPO}@${digest} references ${subject}, which is not in ${IMAGE}"
            exit 1
        fi
        SUFFIX_FOR_DIGEST[$digest]="${SUFFIX_FOR_DIGEST[$subject]}-attestation"
    done <<< "${ATTESTATIONS}"
fi

for digest in "${!SUFFIX_FOR_DIGEST[@]}"; do
    echo "Tagging ${REPO}@${digest} as ${TAG}-${SUFFIX_FOR_DIGEST[$digest]}"
    retry oras tag "${REPO}@${digest}" "${TAG}-${SUFFIX_FOR_DIGEST[$digest]}"
done
