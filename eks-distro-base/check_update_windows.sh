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

IMAGE_NAME="$1"
AL_TAG="$2"
NAME_FOR_TAG_FILE="$3"

function retry() {
    local n=1
    local max=120
    local delay=5
    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
            ((n++))
            >&2 echo "Command failed. Attempt $n/$max:"
            sleep $delay;
            else
            fail "The command has failed after $n attempts."
            fi
        }
    done
}


BASE_IMAGE_TAG="$(yq e ".windows.\"$NAME_FOR_TAG_FILE\"" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)"

mkdir -p check-update

if [ "$BASE_IMAGE_TAG" = "null" ]; then
    echo "updates" > ./check-update/${NAME_FOR_TAG_FILE} 
    exit 0
fi

BASE_IMAGE=public.ecr.aws/eks-distro-build-tooling/$IMAGE_NAME

# Pull the buildinfo from the last published image which will contain the sha of the two windows images
# used to build that image. Compare these sha with the current shas tagged upstream for this given
# windows version. If the current tag points to a different sha, the image needs updating
IMAGE_SHA=$(retry docker buildx imagetools inspect $BASE_IMAGE:$BASE_IMAGE_TAG --raw | jq -r '.manifests[0].digest')
DIGEST_SHA=$(retry docker buildx imagetools inspect $BASE_IMAGE@$IMAGE_SHA --raw | jq -r '.config.digest')
BUILDINFO=$(retry docker buildx imagetools inspect $BASE_IMAGE@$DIGEST_SHA --raw | jq -r '."moby.buildkit.buildinfo.v1"' | base64 -d)

for variant in "nanoserver" "servercore"; do
    SOURCE_IMAGE_REF=$(jq -r ".sources | .[] | select(.ref | contains(\"$variant\")) | .ref" <<< "$BUILDINFO")
    SOURCE_IMAGE_PIN=$(jq -r ".sources | .[] | select(.ref | contains(\"$variant\")) | .pin" <<< "$BUILDINFO")
    
    if [ "$(retry docker buildx imagetools inspect --raw $SOURCE_IMAGE_REF@$SOURCE_IMAGE_PIN)" != "$(retry docker buildx imagetools inspect --raw $SOURCE_IMAGE_REF)" ]; then
        echo "updates" > ./check-update/${NAME_FOR_TAG_FILE}
        exit 0
    fi
done

echo "none" > ./check-update/${NAME_FOR_TAG_FILE}
