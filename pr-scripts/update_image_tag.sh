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
OLD_TAG="$2"
NEW_TAG="$3"
FILEPATH="$4"
USE_YQ="$5"

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
    SED=gsed
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

OTHER_CLONE_ROOT=${OTHER_CLONE_ROOT:-${SCRIPT_ROOT}/../../..}

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

REPO_PATH=${OTHER_CLONE_ROOT}/${ORIGIN_ORG}/${REPO}
cp -rf ${SCRIPT_ROOT}/../eks-distro-base-minimal-packages $REPO_PATH
cp -rf ${SCRIPT_ROOT}/../eks-distro-base-updates $REPO_PATH
cd $REPO_PATH
pwd

if [ "$USE_YQ" = "true" ]; then
    yq -i e "$NEW_TAG" EKS_DISTRO_TAG_FILE.yaml   
else
    for FILE in $(find ./ -type f -name "$FILEPATH"); do
        $SED -i "s,${OLD_TAG},${NEW_TAG}," $FILE
    done
fi
