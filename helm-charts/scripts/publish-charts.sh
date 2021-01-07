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

CHARTS_DIR=$1

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source $SCRIPT_ROOT/lib.sh

mkdir -p "${BUILD_DIR}"

if [ -e "${CHARTS_DIR}/Chart.yaml" ]
then
	helm package "${CHARTS_DIR}/" --destination "${BUILD_DIR}/stable"
else
	helm package "${CHARTS_DIR}/"* --destination "${BUILD_DIR}/stable"
fi

set +e # Should have exit code 18
RETURN_CODE="$(curl --write-out '%{http_code}' --silent --output /dev/null -X HEAD ${REPO_URL}/index.yaml)"
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
    curl -o index.yaml --silent "${REPO_URL}/index.yaml"
fi
helm repo index $BUILD_DIR/stable --url $REPO_URL $MERGE_ARG
aws s3 cp --recursive --acl public-read ${BUILD_DIR}/stable  "s3://${CHART_BUCKET}"
echo "✅ Published charts"
