#!/usr/bin/env bash
# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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

# update_image_tag.sh for minimal must be run before eks-distro-base. It uses
# EKS_DISTRO_BASE_TAG_FILE as a reference in "check_update.sh" for any required
# updates. If eks-distro-minimal-base needs updates, we know those same updates
# apply to eks-distro-base, but not the inverse.
${SCRIPT_ROOT}/../pr-scripts/update_local_branch.sh eks-distro-build-tooling
${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh eks-distro-build-tooling '.*' $IMAGE_TAG EKS_DISTRO_MINIMAL_BASE_TAG_FILE
${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh eks-distro-build-tooling '.*' $IMAGE_TAG EKS_DISTRO_BASE_TAG_FILE
${SCRIPT_ROOT}/../pr-scripts/create_pr.sh eks-distro-build-tooling '.*' $IMAGE_TAG 'EKS_DISTRO*_BASE_TAG_FILE'

${SCRIPT_ROOT}/../pr-scripts/update_local_branch.sh eks-distro
${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh eks-distro '.*' $IMAGE_TAG EKS_DISTRO_MINIMAL_BASE_TAG_FILE
${SCRIPT_ROOT}/../pr-scripts/update_image_tag.sh eks-distro '.*' $IMAGE_TAG EKS_DISTRO_BASE_TAG_FILE
${SCRIPT_ROOT}/../pr-scripts/create_pr.sh eks-distro '.*' $IMAGE_TAG 'EKS_DISTRO*_BASE_TAG_FILE'
