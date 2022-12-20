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

IMAGE_NAME="$1"
IMAGE="$2"
WINDOWS_IMAGE_VERSION="$3"
WINDOWS_IMAGE_REGISTRY="$4"
WINDOWS_BASE_IMAGE_NAME="$5"

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

if [ ! -f /tmp/$IMAGE_NAME-metadata.json ]; then
    echo "No metadata file for image: /tmp/$IMAGE_NAME-metadata.json!"
    exit 1
fi

# need to remove mediaType from descri since buildx segfaults when it is set
jq -r '."containerimage.descriptor"  | {size, digest}' /tmp/$IMAGE_NAME-metadata.json > /tmp/$IMAGE_NAME-descr.json

retry docker buildx imagetools inspect --raw $WINDOWS_IMAGE_REGISTRY/$WINDOWS_BASE_IMAGE_NAME:$WINDOWS_IMAGE_VERSION \
    | jq '.manifests[0] | {platform}' \
    | jq add -s - /tmp/$IMAGE_NAME-descr.json > /tmp/$IMAGE_NAME-descr-final.json


retry docker buildx imagetools create --dry-run -f /tmp/$IMAGE_NAME-descr-final.json -t $IMAGE > /tmp/$IMAGE_NAME-manfiest-final.json

cat  /tmp/$IMAGE_NAME-manfiest-final.json

if [ "$(jq '.manifests[].platform | select( has("os.version") == true ) | ."os.version"' /tmp/$IMAGE_NAME-manfiest-final.json | wc -l | xargs)" != "1" ]; then
    echo "windows images do not have os.version set!"
    exit 1
fi

retry docker buildx imagetools create -f /tmp/$IMAGE_NAME-descr-final.json -t $IMAGE 

retry docker buildx imagetools inspect $IMAGE

rm -rf /tmp/$IMAGE_NAME-*.json
