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

WINDOWS_IMAGE_REGISTRY=mcr.microsoft.com/windows
WINDOWS_BASE_IMAGE_NAME=nanoserver
WINDOWS_ADDON_IMAGE_NAME=servercore

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

# Extract the windows version (e.g. ltsc2022) from the tag file entry name
WINDOWS_VERSION="${NAME_FOR_TAG_FILE##*-}"

# Read the OCI annotations from the published image manifest to get the upstream
# digests that were recorded at build time. Compare them against what the upstream
# tags currently resolve to. If they differ, Microsoft pushed a new image.
PUBLISHED_MANIFEST=$(retry docker buildx imagetools inspect --raw $BASE_IMAGE:$BASE_IMAGE_TAG)

# Get the manifest entry for the windows/amd64 platform (skip attestation manifests)
WINDOWS_MANIFEST_DIGEST=$(jq -r '.manifests[] | select(.platform.os == "windows" and .platform.architecture == "amd64") | .digest' <<< "$PUBLISHED_MANIFEST" | head -1)

if [ -z "$WINDOWS_MANIFEST_DIGEST" ] || [ "$WINDOWS_MANIFEST_DIGEST" = "null" ]; then
    echo "Could not find windows/amd64 manifest in published image, triggering rebuild" >&2
    echo "updates" > ./check-update/${NAME_FOR_TAG_FILE}
    exit 0
fi

# Inspect the individual manifest to get annotations
IMAGE_MANIFEST=$(retry docker buildx imagetools inspect --raw $BASE_IMAGE:$BASE_IMAGE_TAG@$WINDOWS_MANIFEST_DIGEST)

STORED_NANOSERVER_DIGEST=$(jq -r '.annotations."org.opencontainers.image.base.digest" // empty' <<< "$IMAGE_MANIFEST")
STORED_SERVERCORE_DIGEST=$(jq -r '.annotations."com.amazonaws.eks.servercore.digest" // empty' <<< "$IMAGE_MANIFEST")

if [ -z "$STORED_NANOSERVER_DIGEST" ] || [ -z "$STORED_SERVERCORE_DIGEST" ]; then
    echo "No upstream digest annotations found in published image, triggering rebuild" >&2
    echo "updates" > ./check-update/${NAME_FOR_TAG_FILE}
    exit 0
fi

# Get current upstream digests
CURRENT_NANOSERVER_DIGEST=$(retry docker buildx imagetools inspect --raw $WINDOWS_IMAGE_REGISTRY/$WINDOWS_BASE_IMAGE_NAME:$WINDOWS_VERSION \
    | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest')
CURRENT_SERVERCORE_DIGEST=$(retry docker buildx imagetools inspect --raw $WINDOWS_IMAGE_REGISTRY/$WINDOWS_ADDON_IMAGE_NAME:$WINDOWS_VERSION \
    | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest')

echo "Stored nanoserver digest: $STORED_NANOSERVER_DIGEST" >&2
echo "Current nanoserver digest: $CURRENT_NANOSERVER_DIGEST" >&2
echo "Stored servercore digest: $STORED_SERVERCORE_DIGEST" >&2
echo "Current servercore digest: $CURRENT_SERVERCORE_DIGEST" >&2

if [ "$STORED_NANOSERVER_DIGEST" != "$CURRENT_NANOSERVER_DIGEST" ] || [ "$STORED_SERVERCORE_DIGEST" != "$CURRENT_SERVERCORE_DIGEST" ]; then
    echo "Upstream digest has changed, rebuild needed" >&2
    echo "updates" > ./check-update/${NAME_FOR_TAG_FILE}
    exit 0
fi

echo "none" > ./check-update/${NAME_FOR_TAG_FILE}
