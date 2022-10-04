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
FILEPATH="$2"

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
    SED=gsed
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

CHANGED_FILE="tag file(s)"
if [[ $REPO =~ "prow-jobs" ]]; then
    CHANGED_FILE="Prowjobs"
fi
if [[ $JOB_NAME =~ "prow-deck-tooling" ]]; then
    CHANGED_FILE="Prow controlplane Helm chart values"
fi

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

COMMIT_MESSAGE="[PR BOT] Update base image tag file(s)"
if [[ $REPO =~ "prow-jobs" ]]; then
    COMMIT_MESSAGE="[PR BOT] Update builder-base image tag in Prow jobs"
fi
if [[ $JOB_NAME =~ "prow-deck-tooling" ]]; then
    COMMIT_MESSAGE="[PR BOT] Update deck image in Prow controlplane Helm chart values"
fi

PR_TITLE="Update base image tag in ${CHANGED_FILE}"
if [[ $REPO =~ "prow-jobs" ]]; then
    PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/builder_base_pr_body
else
    if [[ $JOB_NAME =~ "prow-deck-tooling" ]]; then
        PR_TITLE="Update deck image tag in ${CHANGED_FILE}"
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/prow_deck_pr_body
    else
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/eks_distro_base_other_repo_pr_body
        if [ $REPO = "eks-distro-build-tooling" ]; then
            PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/eks_distro_base_pr_body
        fi
        cp $PR_BODY_FILE ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
        $SED -i "s,in .* with,in ${CHANGED_FILE} with," $PR_BODY_FILE
        
        for FILE in $(find ${SCRIPT_ROOT}/../eks-distro-base-updates -type f -name "update_packages*" ); do
            UPDATE_PACKAGES="$(cat ${FILE})"
            if [ "$UPDATE_PACKAGES" != "" ]; then
                VARIANT=$(basename ${FILE} | sed 's/update_packages-//')
                printf "\n${VARIANT}\nThe following yum packages were updated:\n\`\`\`bash\n${UPDATE_PACKAGES}\n\`\`\`\n" >> $PR_BODY_FILE
            fi
        done
    fi
fi

PROW_BUCKET_NAME=$(echo $JOB_SPEC | jq -r ".decoration_config.gcs_configuration.bucket" | awk -F// '{print $NF}')
printf "\nClick [here](https://prow.eks.amazonaws.com/view/s3/$PROW_BUCKET_NAME/logs/$JOB_NAME/$BUILD_ID) to view job logs.
\nBy submitting this pull request,\
I confirm that you can use, modify, copy,\
and redistribute this contribution,\
under the terms of your choice." >> $PR_BODY_FILE
PR_BODY=$(cat $PR_BODY_FILE)
PR_BRANCH="image-tag-update"

cd ${SCRIPT_ROOT}/../../../${ORIGIN_ORG}/${REPO}

if [[ "$(basename "$FILEPATH")" != "$FILEPATH" ]]; then
    cd $(dirname $FILEPATH)
    FILEPATH="$(basename $FILEPATH)"
fi

for FILE in $(find ./ -type f -name "$FILEPATH" ); do
    git add $FILE
done

cd ${SCRIPT_ROOT}/../../../${ORIGIN_ORG}/${REPO}
if [ $REPO = "eks-distro-build-tooling" ]; then
    git add ./eks-distro-base-minimal-packages/. ./eks-distro-base-updates/.
fi
if [[ $REPO =~ "prow-jobs" ]]; then
    git add ./BUILDER_BASE_TAG_FILE
fi

FILES_ADDED=$(git diff --staged --name-only)
if [ "$FILES_ADDED" = "" ]; then
    exit 0
fi

if [ "$JOB_TYPE" = "presubmit" ]; then
    git diff --staged
    exit 0
fi

git commit -m "$COMMIT_MESSAGE"

ssh-agent bash -c 'ssh-add /secrets/ssh-secrets/ssh-key; ssh -o StrictHostKeyChecking=no git@github.com; git push -u origin $PR_BRANCH -f'

gh auth login --with-token < /secrets/github-secrets/token

PR_EXISTS=$(gh pr list | grep -c "${PR_BRANCH}" || true)
if [ $PR_EXISTS -eq 0 ]; then
  gh pr create --title "$PR_TITLE" --body "$PR_BODY" --label "do-not-merge/hold"
fi
