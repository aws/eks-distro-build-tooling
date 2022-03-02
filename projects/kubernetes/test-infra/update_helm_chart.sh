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

PATCH=patch
if [[ "$(uname -s)" == "Darwin" ]]; then
    PATCH=gpatch
fi

# Workaround to YQ aggressively removing blank lines from YAMLs.
# Generates an updated values YAML on the fly, and generates a diff
# ignoring blank lines, then patches the original YAML file with the diff
function patch::yaml::with::readability(){
    charts_dir=$1
    filename=$2
    yq_eval_command=$3
    TMPDIR=$(mktemp -d)
    yq eval "$yq_eval_command" $charts_dir/$filename > $TMPDIR/updated-$filename
    (diff -U0 -w -b --ignore-blank-lines $charts_dir/$filename $TMPDIR/updated-$filename || true) > $TMPDIR/$filename.diff
    $PATCH $charts_dir/$filename < $TMPDIR/$filename.diff
}

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

IMAGE="$1"
VALUES_PATH="$2"
UPDATE_CHART="$3"

if [ $REPO_OWNER = "aws" ]; then
    ORIGIN_ORG="eks-distro-pr-bot"
else
    ORIGIN_ORG=$REPO_OWNER
fi

REPO_PATH=${SCRIPT_ROOT}/../../../../../${ORIGIN_ORG}/eks-distro-build-tooling
cd $REPO_PATH

CONTROLPLANE_CHARTS_DIR=$REPO_PATH/helm-charts/stable/prow-control-plane
HELM_VALUES_FILE=$CONTROLPLANE_CHARTS_DIR/values.yaml
HELM_CHART_FILE=$CONTROLPLANE_CHARTS_DIR/Chart.yaml

patch::yaml::with::readability $CONTROLPLANE_CHARTS_DIR "values.yaml" ".$VALUES_PATH = \"$IMAGE\""

# Updating Prow controlplane chart version to the next patch release
if [ $UPDATE_CHART -eq 1 ]; then
    chart_version=$(yq eval ".version" $HELM_CHART_FILE)
    IFS=. read -r major minor patch <<<"$chart_version"
    ((patch++))
    printf -v updated_chart_version '%d.%d.%d' "$major" "$minor" "$((patch))"
    patch::yaml::with::readability $CONTROLPLANE_CHARTS_DIR "Chart.yaml" ".version = \"$updated_chart_version\""
fi
