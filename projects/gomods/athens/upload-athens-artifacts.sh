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

set -x
set -euo pipefail

err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BUILD_DIR="$SCRIPT_ROOT/build"
REPO=$1
CHART_BUCKET=$2
BASE_IMAGE=$3
IMAGE=$4
UPLOAD=$5
BUCKET_URL="https://${CHART_BUCKET}.s3.amazonaws.com"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

git clone $REPO
cd athens
OUTPUT="dest=/tmp/athens.tar"
if [[ $UPLOAD == "true" ]]; then
    OUTPUT="push=true"
fi
buildctl build \
  --frontend dockerfile.v0 \
  --opt platform=linux/amd64 \
  --opt build-arg:BASE_IMAGE=${BASE_IMAGE} \
  --local dockerfile=cmd/proxy/ \
  --local context=. \
  --output type=oci,oci-mediatypes=true,name=${IMAGE},$OUTPUT
cd ..
rm -rf athens

# We need to change this repository to the upstream one,
# once the following PR is merged.
# https://github.com/gomods/athens/pull/1677
git clone https://github.com/bnrjee/athens
cd athens
git checkout origin/sa_override
if [[ $UPLOAD == "true" ]]
then
    helm package "charts/"* --destination stable
    set +e
    RETURN_CODE="$(curl --write-out '%{http_code}' --silent --output /dev/null -X HEAD ${BUCKET_URL}/index.yaml)"
    CURL_EXIT_CODE=$?
    set -e
    if [ "$CURL_EXIT_CODE" != "18" ] && [ "$CURL_EXIT_CODE" != "0" ]; then
        echo "Error! Got exit code $CURL_EXIT_CODE from curl"
        exit 1
    fi
    MERGE_ARG=""
    # When initially creating the repo, we need to skip adding the merge argument
    if [ "$RETURN_CODE" == "200" ]; then
        MERGE_ARG="--merge index.yaml"
        curl -o index.yaml --silent "${BUCKET_URL}/index.yaml"
    fi
    helm repo index stable --url ${BUCKET_URL} $MERGE_ARG
    aws s3 cp --recursive --acl public-read stable  "s3://${CHART_BUCKET}"
fi
cd ..
rm -rf athens

cd $SCRIPT_ROOT
rm -rf $BUILD_DIR
