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
PR_BRANCH="${3:-image-tag-update}"
EXTRA_PR_BODY="${4:-}"

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
    SED=gsed
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

OTHER_CLONE_ROOT=${OTHER_CLONE_ROOT:-${SCRIPT_ROOT}/../../..}

MINIMAL_IMAGE_REBUILD_PJ_NAME="quarterly-minimal-image-rebuild"

CHANGED_FILE="tag file(s)"
CHANGED_COMPONENT="base image"
if [[ $REPO =~ "prow-jobs" ]]; then
    CHANGED_FILE="Prowjobs"
    CHANGED_COMPONENT="builder-base image tag"
fi
if [[ $JOB_NAME =~ "prow-deck-tooling" ]]; then
    CHANGED_FILE="Prow controlplane Helm chart"
    CHANGED_COMPONENT="Prow component images"
fi
if [[ $JOB_NAME =~ $MINIMAL_IMAGE_REBUILD_PJ_NAME ]]; then
    CHANGED_FILE="EKS_DISTRO_TAG_FILE"
    CHANGED_COMPONENT="image tags"
fi

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

PR_TITLE="Update ${CHANGED_COMPONENT} in ${CHANGED_FILE}"
COMMIT_MESSAGE="[PR BOT] ${PR_TITLE}"

if [[ $REPO =~ "prow-jobs" ]]; then
    PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/builder_base_pr_body
else
    if [[ $JOB_NAME =~ "prow-deck-tooling" ]]; then
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/prow_cp_pr_body
    elif [[ $JOB_NAME =~ $MINIMAL_IMAGE_REBUILD_PJ_NAME ]]; then
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/rebuild-minimal-images-pr-body
    else
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/eks_distro_base_other_repo_pr_body
        if [ $REPO = "eks-distro-build-tooling" ]; then
            PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/eks_distro_base_pr_body
        fi
        cp $PR_BODY_FILE ${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
        PR_BODY_FILE=${SCRIPT_ROOT}/../pr-scripts/${REPO}_pr_body
        $SED -i "s,in .* with,in ${CHANGED_FILE} with," $PR_BODY_FILE
    fi
fi

if [ -n "${EXTRA_PR_BODY}" ]; then
    printf "${EXTRA_PR_BODY}" >> $PR_BODY_FILE
fi

# Adding this here to include the "do-not-merge/hold" label. Trying to use the gh client with the --label arg will not succeed
# as the bot doesn't have permission to add labels. Doing it this way our Prow chatops will pick it up and add it.
printf "\n/hold\n" >> $PR_BODY_FILE

PROW_BUCKET_NAME=$(echo $JOB_SPEC | jq -r ".decoration_config.gcs_configuration.bucket" | awk -F// '{print $NF}')
printf "\nClick [here](https://prow.eks.amazonaws.com/view/s3/$PROW_BUCKET_NAME/logs/$JOB_NAME/$BUILD_ID) to view job logs.
\nBy submitting this pull request,\
I confirm that you can use, modify, copy,\
and redistribute this contribution,\
under the terms of your choice." >> $PR_BODY_FILE
PR_BODY=$(cat $PR_BODY_FILE)


cd ${OTHER_CLONE_ROOT}/${ORIGIN_ORG}/${REPO}

if [[ "$(basename "$FILEPATH")" != "$FILEPATH" ]]; then
    cd $(dirname $FILEPATH)
    FILEPATH="$(basename $FILEPATH)"
fi

for FILE in $(find ./ -type f -name "$FILEPATH" ); do
    git add $FILE
done

cd ${OTHER_CLONE_ROOT}/${ORIGIN_ORG}/${REPO}
if [ $REPO = "eks-distro-build-tooling" ]; then
    git add ./eks-distro-base-minimal-packages/. ./eks-distro-base-updates/.
fi
if [[ $REPO =~ "prow-jobs" ]]; then
    git add ./BUILDER_BASE_TAG_FILE
fi
if [[ $JOB_NAME =~ $MINIMAL_IMAGE_REBUILD_PJ_NAME ]]; then
 git add ../EKS_DISTRO_TAG_FILE.yaml
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

PR_EXISTS=$(GH_PAGER='' gh pr list --json number -H "${PR_BRANCH}")
if [ "$PR_EXISTS" = "[]" ]; then
  gh pr create --title "$PR_TITLE" --body "$PR_BODY"
fi
