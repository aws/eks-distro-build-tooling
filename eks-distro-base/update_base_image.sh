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

bash ./eks-distro-base/install_gh.sh
export DATE_EPOCH=$(date "+%F-%s")
make release -C eks-distro-base DEVELOPMENT=false IMAGE_TAG=${DATE_EPOCH}
bash ./eks-distro-base/create_pr.sh eks-distro-build-tooling '.*' ${DATE_EPOCH} TAG_FILE
bash ./eks-distro-base/create_pr.sh eks-distro 'BASE_TAG?=.*' 'BASE_TAG?='"${DATE_EPOCH}" Makefile
