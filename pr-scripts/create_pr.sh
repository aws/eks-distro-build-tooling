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

REPO="$1"
OLD_TAG="$2"
NEW_TAG="$3"
FILEPATH="$4"

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
    SED=gsed
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ $REPO = "eks-distro-build-tooling" ] || [ $REPO = "eks-distro" ]; then
    CHANGED_FILE="Tag file"
elif [ $REPO = "eks-distro-prow-jobs" ]; then
    CHANGED_FILE="Prow jobs"
fi

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

COMMIT_MESSAGE="[PR BOT] Update EKS Distro base image tag(s)"
if [ $REPO = "eks-distro-prow-jobs" ]; then
    COMMIT_MESSAGE="[PR BOT] Update builder-base image tag in Prow jobs"
fi

PR_TITLE="Update base image tag in ${CHANGED_FILE}"
if [ $REPO = "eks-distro-build-tooling" ] || [ $REPO = "eks-distro" ]; then
    $SED -i "s,in .* with,in ${CHANGED_FILE} with," ${SCRIPT_ROOT}/../pr-scripts/eks_distro_base_pr_body
    cp ${SCRIPT_ROOT}/../pr-scripts/eks_distro_base_pr_body ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
    UPDATE_PACKAGES="$(cat ${SCRIPT_ROOT}/../eks-distro-base/update_packages)"
    if [ "$UPDATE_PACKAGES" != "" ]; then
        printf "\nThe following yum packages were updated:\n\`\`\`bash\n${UPDATE_PACKAGES}\n\`\`\`\n" >> ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
    fi
    printf "\nBy submitting this pull request,\
    I confirm that you can use, modify, copy,\
    and redistribute this contribution,\
    under the terms of your choice." >> ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body

    PR_BODY=$(cat ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body)
    rm ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
else
    PR_BODY=$(cat ${SCRIPT_ROOT}/../pr-scripts/builder_base_pr_body)
fi
PR_BRANCH="image-tag-update"

cd ${SCRIPT_ROOT}/../../../${ORIGIN_ORG}/${REPO}

for FILE in $(find ./ -type f -name "$FILEPATH" ); do
    git add $FILE
done
if [ $REPO = "eks-distro-prow-jobs" ]; then
    git add ./BUILDER_BASE_TAG_FILE
fi

FILES_ADDED=$(git diff --staged --name-only)
if [ "$FILES_ADDED" = "" ]; then
    exit 0
fi

git commit -m "$COMMIT_MESSAGE"
if [ "$JOB_TYPE" = "presubmit" ]; then
    exit 0
fi
ssh-agent bash -c 'ssh-add /secrets/ssh-secrets/ssh-key; ssh -o StrictHostKeyChecking=no git@github.com; git push -u origin $PR_BRANCH -f'

gh auth login --with-token < /secrets/github-secrets/token

PR_EXISTS=$(gh pr list | grep -c "${PR_BRANCH}" || true)
if [ $PR_EXISTS -eq 0 ]; then
  gh pr create --title "$PR_TITLE" --body "$PR_BODY"
fi
