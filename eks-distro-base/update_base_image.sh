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
IMAGE_TAG=$1
IMAGE_NAME=$2
AL_TAG=$3
PR_BRANCH="$4"

if [ "$AL_TAG" != "windows" ]; then
    AL_TAG="al$AL_TAG"
fi

OLD_TAG="$(yq e ".al$AL_TAG.\"$IMAGE_NAME\"" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)"
BASE_IMAGE_TAG_FILE="$(echo ${IMAGE_NAME^^} | sed 's/[\.-]/_/g')_TAG_FILE"

${SCRIPT_ROOT}/../pr-scripts/update_local_branch.sh eks-distro-build-tooling $PR_BRANCH
${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh eks-distro-build-tooling $OLD_TAG ".$AL_TAG.\"$IMAGE_NAME\" |= \"$IMAGE_TAG\"" "EKS_DISTRO_TAG_FILE.yaml" true
