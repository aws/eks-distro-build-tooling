#!/usr/bin/env bash
#Script to conigure git and  push new image tag to origin branch

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
REVIEWERS=(
  "micah-hausler"
  "vivek-koppuru"
)

cd ../${REPO}
git config user.email user.email "prow@amazonaws.com"
git config user.name "Prow Bot"
git remote add upstream git@github.com:aws/${REPO}.git
git remote add origin git@github.com:eks-distro-bot/${REPO}.git
git fetch upstream
git rebase upstream/main
git checkout -b image-update-branch

for FILE in $(find ./ -name $FILEPATH); do
    if [ $REPO = "eks-distro" ]; then
        if [ $(dirname $FILE) = "." ]; then
            OLD_TAG="^BASE_IMAGE?=\(.*\):.*"
            NEW_TAG="BASE_IMAGE?=\1:${DATE_EPOCH}"
        fi
    fi
    sed -i "s,${OLD_TAG},${NEW_TAG}," $FILE
    git add $FILE
done
git commit -m "Update EKS Distro base image tag"
git push -u origin image-update-branch -f

gh auth login --with-token < /secrets/github-auth/token
IFS=,
gh create pr --title $PR_TITLE --body $PR_BODY --reviewer "${REVIEWERS[*]}" --draft
