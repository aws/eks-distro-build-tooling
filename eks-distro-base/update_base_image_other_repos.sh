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

OTHER_CLONE_ROOT=${OTHER_CLONE_ROOT:-${SCRIPT_ROOT}/../../..}
if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

EXTRA_PR_BODY=""

REPOS=(eks-distro eks-anywhere-build-tooling eks-anywhere)
for repo in "${REPOS[@]}"; do
    ${SCRIPT_ROOT}/../pr-scripts/update_local_branch.sh "$repo"
done
while IFS=, read -r key
do
    key=${key:2} # strip leading - space
    while IFS=, read -r image
    do
        image=${image:2} # strip leading - space
        BASE_IMAGE_TAG_FILE="$(echo ${image^^} | tr '-' '_')_TAG_FILE"

        if [[ "$key" == "al2023" ]]; then
            BASE_IMAGE_TAG_FILE="$(echo ${image^^} | tr '-' '_')_AL2023_TAG_FILE"
        fi

        IMAGE_TAG=$(yq e ".$key.\"$image\"" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)
        # we will set the tag to null to trigger new builds. we dont want PRs being open setting
        # tag file values to null
        if [[ "${IMAGE_TAG}" = "null" ]]; then
            continue
        fi
        for repo in "${REPOS[@]}"; do
            ${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh "$repo" '.*' $IMAGE_TAG $BASE_IMAGE_TAG_FILE

            if [ "$(git -C ${OTHER_CLONE_ROOT}/${ORIGIN_ORG}/${repo} status --porcelain -- $BASE_IMAGE_TAG_FILE | wc -l)" -gt 0 ]; then
                UPDATE_PACKAGES="$(cat "${SCRIPT_ROOT}/../eks-distro-base-updates/${key#al}/update_packages-${image}")"
                if [ "$UPDATE_PACKAGES" != "" ]; then
                    EXTRA_PR_BODY+="\n${BASE_IMAGE_TAG_FILE}\nThe following yum packages were updated:\n\`\`\`bash\n${UPDATE_PACKAGES}\n\`\`\`\n"
                fi
            fi
        done
    done < <(yq e ".$key | keys" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)
done < <(yq e "keys" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)

for repo in "${REPOS[@]}"; do
   ${SCRIPT_ROOT}/../pr-scripts/create_pr.sh "$repo" 'EKS_DISTRO*_TAG_FILE' "image-tag-update" "$EXTRA_PR_BODY"
done
