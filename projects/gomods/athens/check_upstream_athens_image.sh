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

set -e
set -o pipefail
set -x

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
IMAGE_TAG_FILE="${SCRIPT_ROOT}/IMAGE_TAG"

UPSTREAM_IMAGE="docker.io/gomods/athens"

LATEST_TAG=$(skopeo list-tags "docker://${UPSTREAM_IMAGE}" \
  | jq -r '.Tags[]' \
  | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -n1)

if [ -z "$LATEST_TAG" ]; then
  echo "Failed to determine latest upstream Athens image tag"
  exit 1
fi

CURRENT_TAG=$(cat "$IMAGE_TAG_FILE")
if [ "$LATEST_TAG" != "$CURRENT_TAG" ]; then
  echo "Updating Athens IMAGE_TAG: ${CURRENT_TAG} -> ${LATEST_TAG}"
  printf '%s\n' "$LATEST_TAG" > "$IMAGE_TAG_FILE"
else
  echo "Athens IMAGE_TAG already at latest: ${CURRENT_TAG}"
fi
