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

if [ $REPO = "eks-distro-build-tooling" ]; then
    FILENAME="Tag file"
elif [ $REPO = "eks-distro" ]; then
    FILENAME="Makefile"
else
    FILENAME="EKS Distro base periodic"
fi

PR_TITLE="Update base image tag in ${FILENAME}"
PR_BODY="This PR updates the base image tag in ${FILENAME} with \
the tag of the newly-built EKS Distro base image"

cd ../${REPO}
git remote add upstream git@github.com:aws/${REPO}.git
git remote add origin git@github.com:abhay-krishna/${REPO}.git
#git fetch upstream
#git rebase upstream/main
git checkout -b image-tag-update

for FILE in $(find ./ -name $FILEPATH); do
    if [ $REPO = "eks-distro" ] ; then
        if [ $(dirname $FILE) = "." ]; then
            OLD_TAG="^BASE_IMAGE?=\(.*\):.*"
            NEW_TAG="BASE_IMAGE?=\1:${DATE_EPOCH}"
        else
            OLD_TAG="$2"
            NEW_TAG="$3"
        fi
    fi
    sed -i "s,${OLD_TAG},${NEW_TAG}," $FILE
    git add $FILE
done
git commit -m "Update EKS Distro base image tag"
ssh-agent bash -c 'ssh-add /secrets/ssh-secrets/ssh-key; ssh -o StrictHostKeyChecking=no git@github.com; git push -u origin image-tag-update -f'

gh auth login --with-token < /secrets/github/token
IFS=,
gh pr create --title $PR_TITLE --body $PR_BODY --draft
