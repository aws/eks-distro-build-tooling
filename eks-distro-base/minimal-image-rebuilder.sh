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


# This script searches the EKS_DISTRO_TAG_FILE.yaml where we keep the latest
# builds of the minimal images. Watchers and prowjobs allow for triggering 
# rebuilds of the minimal images by setting the value to `null`. This script
# sets all values in that file to `null` which if merged would trigger a rebuild
# of all minimal images if needed.

set -e
set -o pipefail
set -x

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
	SED=gsed
fi

$SED -ri 's/:\s(.+)$/: null/g' ${SCRIPT_ROOT}/../EKS_DISTRO_TAG_FILE.yaml
