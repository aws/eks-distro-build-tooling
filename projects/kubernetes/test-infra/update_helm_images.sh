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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

IMAGES=${1?Specify first argument - Images to be replaced in Helm values}
VALUE_PATHS=${2?Specify second argument - Path to var in values.yaml to update, ex: deck.image}

IMAGES=(${IMAGES// / })
VALUE_PATHS=(${VALUE_PATHS// / })

${SCRIPT_ROOT}/../../../pr-scripts/update_local_branch.sh eks-distro-build-tooling
	
for (( i=0; i<${#IMAGES[*]}; ++i)); do \
    ${SCRIPT_ROOT}/update_helm_chart.sh "${IMAGES[$i]}" "${VALUE_PATHS[$i]}" $(( $i==${#IMAGES[*]} - 1 )); \
done

${SCRIPT_ROOT}/../../../pr-scripts/create_pr.sh eks-distro-build-tooling 'helm-charts/stable/prow-control-plane/*.yaml'
