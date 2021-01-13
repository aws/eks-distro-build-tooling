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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN_FLAG=$1

if [ $DRY_RUN_FLAG = "--dry-run" ]; then
    NEW_TAG=$PULL_PULL_SHA
else
    NEW_TAG=$PULL_BASE_SHA
fi

${REPO_ROOT}/../pr-scripts/install_gh.sh
${REPO_ROOT}/../pr-scripts/create_pr.sh eks-distro-prow-jobs 'builder:.*' 'builder:'"$NEW_TAG" *.yaml $DRY_RUN_FLAG
