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

set -x
set -euo pipefail

CHARTS_DIR=$1

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
REMOTE_URL="https://github.com/aws/eks-distro-build-tooling.git"

# PULL_BASE_SHA is environment variable set by the presubmit job. More info here: https://github.com/kubernetes/test-infra/blob/master/prow/jobs.md#job-environment-variables
PREV_RELEASE_HASH=${PULL_BASE_SHA}
git fetch $REMOTE_URL $PREV_RELEASE_HASH

EXIT_CODE=0

cd $CHARTS_DIR
for chart in *; do
  DIFF_CHECK_TARGETS="$chart/templates $chart/values.yaml"
  if [ $chart = "amazon-eks-pod-identity-webhook" ]; then
    DIFF_CHECK_TARGETS="$chart/config $DIFF_CHECK_TARGETS"
  fi
  CHART_EXISTED=$(git ls-tree -r ${PREV_RELEASE_HASH} --name-only | grep -c ${chart}/Chart.yaml || true)
  if [ $CHART_EXISTED -eq 0 ]; then
    echo "✅ This is the first release of chart $chart, nothing to compare"
  elif git diff-index ${PREV_RELEASE_HASH} --quiet -- $DIFF_CHECK_TARGETS --; then
    echo "✅ Chart $chart has no changes since last release"
  else
    CURR_VERSION=$(grep "version:" $chart/Chart.yaml | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
    PREV_VERSION=$(git show ${PREV_RELEASE_HASH}:helm-charts/stable/${chart}/Chart.yaml | grep "version:" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
    TEMPLATES_CHANGED=false
    if [ "${CURR_VERSION}" = "${PREV_VERSION}" ]; then
      FILES_TO_CHECK="$chart/templates/* $chart/values.yaml"
      if [ $chart = "amazon-eks-pod-identity-webhook" ]; then
        FILES_TO_CHECK="$chart/config/* $FILES_TO_CHECK"
      fi
      for file in $FILES_TO_CHECK; do
        CHANGED_LINES=$(git show -U0 $file | grep '^[+-]' | grep -Ev '^(--- a/|\+\+\+ b/|\+#|-#|\+$)' || true)
        if [ "$CHANGED_LINES" != "" ]; then
          TEMPLATES_CHANGED=true
          break
        fi
      done
      if [ "$TEMPLATES_CHANGED" = "true" ]; then
        echo "❌ Chart $chart has the same Chart version as the last release $PREV_VERSION, but templates have been modified"
        EXIT_CODE=1
      else
        echo "✅ Chart $chart has the same Chart version as the last release $PREV_VERSION and templates have not been modified"
      fi
    else 
      echo "✅ Chart $chart has a different Chart version since the last release ($PREV_VERSION -> $CURR_VERSION)"
    fi
  fi
done
exit $EXIT_CODE
