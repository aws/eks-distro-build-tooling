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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
    UPSTREAM_ORG="aws"
else
    ORIGIN_ORG=$REPO_OWNER
    UPSTREAM_ORG=$REPO_OWNER
fi

PR_BRANCH="image-tag-update"
if [ "$JOB_TYPE" = "presubmit" ]; then
    PR_BRANCH="image-update-branch"
fi
cd ${SCRIPT_ROOT}/../../../${ORIGIN_ORG}/${REPO}
if [ $(git branch --show-current) != $PR_BRANCH ]; then
    git config --global push.default current
    git config user.name "EKS Distro PR Bot"
    git config user.email "aws-model-rocket-bots+eksdistroprbot@amazon.com"
    git remote add origin git@github.com:${ORIGIN_ORG}/${REPO}.git
    git remote add upstream https://github.com/${UPSTREAM_ORG}/${REPO}.git
    if [ "$REPO" = "eks-distro-build-tooling" ] && [ "$JOB_TYPE" = "presubmit" ]; then
        git fetch upstream pull/$PULL_NUMBER/head:image-update-branch
        git checkout $PR_BRANCH
    else
        git fetch upstream
        git checkout upstream/main -b $PR_BRANCH
    fi
fi