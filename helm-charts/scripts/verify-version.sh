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

CHARTS_DIR=$1

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
REMOTE_URL="https://github.com/aws/eks-distro-build-tooling.git"

# PULL_PULL_SHA is environment variable set by the presubmit job. More info here: https://github.com/kubernetes/test-infra/blob/master/prow/jobs.md#job-environment-variables
PREV_RELEASE_HASH=${PULL_PULL_SHA}
git fetch $REMOTE_URL $PREV_RELEASE_HASH

EXIT_CODE=0

cd $CHARTS_DIR
for d in */; do
  if git diff-index ${PREV_RELEASE_HASH} --quiet -- $d/templates $d/values.yaml --; then
    echo "✅ $d has no changes since last release"
  else
    CURR_VERSION=$(grep "version:" $d/Chart.yaml | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
    PREV_VERSION=$(git show ${PREV_RELEASE_HASH}:helm-charts/stable/${d}Chart.yaml | grep "version:" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
    if [ "${CURR_VERSION}" = "${PREV_VERSION}" ]; then
      echo "❌ $d has the same Chart version as the last release $PREV_VERSION"
      EXIT_CODE=1
    else 
      echo "✅ $d has a different version since the last release ($PREV_VERSION -> $CURR_VERSION)"
    fi
  fi
done
exit $EXIT_CODE