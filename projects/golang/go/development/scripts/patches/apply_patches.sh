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

BASE_DIRECTORY="$(git rev-parse --show-toplevel)/projects/golang/go/development/scripts/patches/lib/patch.sh"
source "$BASE_DIRECTORY"

set -e
set -o pipefail
set -x

VERSION_DIR=$(realpath "$1")
GOLANG_DIR=$(realpath "$2")
APPLY_CVE_PATCHES="${3:-true}"
APPLY_OTHER_PATCHES="${4:-true}"

clone_golang "$GOLANG_DIR"
check_dirty "$GOLANG_DIR"

if [ "$APPLY_CVE_PATCHES" = "true" ]; then
  apply_cve_patches "$VERSION_DIR" "$GOLANG_DIR"
fi

if [ "$APPLY_OTHER_PATCHES" = "true" ]; then
  apply_other_patches "$VERSION_DIR" "$GOLANG_DIR"
fi
