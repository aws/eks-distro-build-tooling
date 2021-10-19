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

set -euo pipefail

CHARTS_DIR=$1

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source $SCRIPT_ROOT/lib.sh

FAILED=()

cd ${CHARTS_DIR}
for d in */; do
    helm lint ${CHARTS_DIR}/${d} || FAILED+=("${d}")
done

if [ "${#FAILED[@]}" -eq  0 ]; then
    echo "All charts passed linting!"
    exit 0
else
    echo "Helm:"
    for chart in "${FAILED[@]}"; do
        printf "%40s ❌\n" "$chart"
    done
fi
