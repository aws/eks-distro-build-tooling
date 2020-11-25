#!/usr/bin/env bash
set -x
set -euo pipefail

err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source $SCRIPT_ROOT/lib.sh

mkdir -p "${BUILD_DIR}"

helm package "${STABLE}/"* --destination "${BUILD_DIR}/stable"

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
