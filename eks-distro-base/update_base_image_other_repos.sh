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

# Use al2 builds as the base images
AL_TAG=2

REPOS=(eks-distro eks-anywhere-build-tooling eks-anywhere)
for repo in "${REPOS[@]}"; do
    ${SCRIPT_ROOT}/../pr-scripts/update_local_branch.sh "$repo"    
done

while IFS=, read -r image
do
    image=${image:2} # strip leading - space
    BASE_IMAGE_TAG_FILE="$(echo ${image^^} | tr '-' '_')_TAG_FILE"
    IMAGE_TAG=$(yq e ".al$AL_TAG.$image" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)
    # we will set the tag to null to trigger new builds. we dont want PRs being open setting
    # tag file values to null
    if [[ "${IMAGE_TAG}" = "null" ]]; then
        continue
    fi
    for repo in "${REPOS[@]}"; do
        ${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh "$repo" '.*' $IMAGE_TAG $BASE_IMAGE_TAG_FILE
    done
done < <(yq e ".al$AL_TAG | keys" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)

for repo in "${REPOS[@]}"; do
   ${SCRIPT_ROOT}/../pr-scripts/create_pr.sh "$repo" 'EKS_DISTRO*_TAG_FILE'
done
