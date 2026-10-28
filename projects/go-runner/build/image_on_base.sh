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

# Exits 0 only if IMAGE exists and, for every platform, its layers start with
# the layers of BASE_IMAGE. Any other result (missing image, different base,
# lookup error) exits 1 so the caller rebuilds.

set -o errexit
set -o nounset
set -o pipefail

IMAGE="$1"
BASE_IMAGE="$2"
PLATFORMS="${3:-linux/amd64 linux/arm64}"

layers() {
  local ref="$1" platform="$2" os arch digest
  os="${platform%/*}"
  arch="${platform#*/}"
  digest=$(docker manifest inspect "$ref" | jq -r --arg os "$os" --arg arch "$arch" \
    '.manifests[] | select(.platform.os == $os and .platform.architecture == $arch) | .digest' | head -1)
  [ -n "$digest" ] || return 1
  docker manifest inspect "${ref%:*}@${digest}" | jq -r '.layers[].digest'
}

for platform in $PLATFORMS; do
  base_layers=$(layers "$BASE_IMAGE" "$platform") || exit 1
  image_layers=$(layers "$IMAGE" "$platform") || exit 1
  base_count=$(echo "$base_layers" | wc -l)
  if [ "$(echo "$image_layers" | head -n "$base_count")" != "$base_layers" ]; then
    echo "$IMAGE ($platform) is not built on $BASE_IMAGE"
    exit 1
  fi
done
