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


CHART_BUCKET="prowdataclusterstack-316-prowchartsbucket2e50b8d9-8b0f36hrcee8"
REPO_URL="https://${CHART_BUCKET}.s3.amazonaws.com"

CHART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
STABLE="${CHART_ROOT}/stable"
BUILD_DIR="${CHART_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
export PATH="${TOOLS_DIR}:${PATH}"
