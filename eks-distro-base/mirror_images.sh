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

IMAGE_COMPONENT="$1"
BUILT_IMAGE_TAG_FROM_FILE="$2"
LATEST="$3"
IMAGE_REPO="$4"
PUBLIC_IMAGE_REPO="$5"

function build::skopeo::manifest() {
    local -r repo="$1"
    local -r tag="$2"

    local os_override="linux"
    if [[ $IMAGE_COMPONENT = *"windows"* ]]; then
        os_override="windows"
    fi

    skopeo inspect --override-os $os_override --override-arch amd64 --retry-times 5 docker://$repo/$IMAGE_COMPONENT:$tag
}

function build::skopeo::retry_manifest() {
    local -r repo="$1"
    local -r tag="$2"

    #local manifest
    #manifest="$(build::skopeo::manifest $repo $tag 2>&1)"
    if manifest=$(build::skopeo::manifest $repo $tag 2> /dev/null); then
        echo $manfiest
    else
        # skopeo's retry logic will not always retry on timeout errors
        # we are checking for existing manfiest, check if failures are the manifest unknown, if so return
        # if not retry just in case its some other flaky error
        local n=1   
        while build::skopeo::manifest $repo $tag 2&>1 | grep -v "manasdifest unknown"; do
            ((n++))
        done
    fi
}

if [ "$BUILT_IMAGE_TAG_FROM_FILE" = "null" ]; then
    # if tag is null in tag_file we are triggering a rebuild, do not try and mirror
    echo "$IMAGE_COMPONENT's tag was null, skipping mirror."
    exit
fi

if ! build::skopeo::retry_manifest $IMAGE_REPO $BUILT_IMAGE_TAG_FROM_FILE; then
    echo "$IMAGE_REPO/$IMAGE_COMPONENT:$BUILT_IMAGE_TAG_FROM_FILE does not exist but is set in EKS_DISTRO_TAG_FILE.yaml"
    echo "This likely means this image was pushed directly to $PUBLIC_IMAGE_REPO before we changed the jobs to pushed to $IMAGE_REPO"
    echo "This is probably safe to ignore and at a later date this check should be removed"
    
    exit
fi

if build::skopeo::retry_manifest $PUBLIC_IMAGE_REPO $BUILT_IMAGE_TAG_FROM_FILE; then #> /dev/null 2>&1
    MANIFEST="$(build::skopeo::retry_manifest $PUBLIC_IMAGE_REPO $BUILT_IMAGE_TAG_FROM_FILE)"
    echo "$PUBLIC_IMAGE_REPO/$IMAGE_COMPONENT:$BUILT_IMAGE_TAG_FROM_FILE already exists validating '$LATEST' tag(s) all point to same sha"
    
    for tag in $LATEST; do \
        if [ "$MANIFEST" != "$(build::skopeo::retry_manifest $PUBLIC_IMAGE_REPO $tag)" ]; then
            echo "$tag does not point the same sha as $BUILT_IMAGE_TAG_FROM_FILE, something must have gone wrong during a previous mirror!"
            exit 1
        fi
    done

    exit
fi

for tag in $BUILT_IMAGE_TAG_FROM_FILE $LATEST; do \
    echo "Mirroring '$IMAGE_COMPONENT' tag '$BUILT_IMAGE_TAG_FROM_FILE' to '$tag' from $IMAGE_REPO to $PUBLIC_IMAGE_REPO"
    
    skopeo copy --all --retry-times 5 --preserve-digests docker://$IMAGE_REPO/$IMAGE_COMPONENT:$BUILT_IMAGE_TAG_FROM_FILE docker://$PUBLIC_IMAGE_REPO/$IMAGE_COMPONENT:$tag
done
