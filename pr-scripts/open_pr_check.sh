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

REPO="$1"
PR_BRANCH="${2:-image-tag-update}"

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ "$JOB_TYPE" != "periodic" ]; then
    exit 0
fi

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

cd ${SCRIPT_ROOT}/../../../${ORIGIN_ORG}/${REPO}

gh auth login --with-token < /secrets/github-secrets/token

PR_EXISTS=$(gh pr list -H "${PR_BRANCH}" || true)
if [ $PR_EXISTS -eq 1 ]; then
    echo "There is an existing PR already open, please merge/close before building new images!"
    exit 1
fi
