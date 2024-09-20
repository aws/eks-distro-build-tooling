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
set -e
set -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
GO_PREFIX="go"
ARCHITECTURE="linux/amd64" # Currently only build golang-debian image for amd64, if other arches are needed add

OUTPUT_DIR="$1"
GO_BIN_VERSION="$2"

source ${BASE_DIRECTORY}/builder-base/scripts/common_vars.sh

# Download from upstream and validate CHECKSUMs
function build::go::download {
  # Set up specific go version by using go get, additional versions apart from default can be installed by calling
  # the function again with the specific parameter.
  local version=${1}
  local outputDir=${2}
  local archs=${3}

  for arch in ${archs/,/ }; do
    local filename="$outputDir/${arch}/$version.${arch/\//-}.tar.gz"
    if [ ! -f $filename ]; then
      curl -sSLf --retry 5 "https://go.dev/dl/$version.${arch/\//-}.tar.gz" -o $filename --create-dirs
      # TODO: REVERT THIS
      sha256sum=999805bed7d9039ec3da1a53bfbcafc13e367da52aa823cb60b68ba22d44c616

      if [[ $(sha256sum ${filename} | cut -d ' ' -f1) != "${sha256sum}" ]]; then
        echo "CHECKSUMs don't match"
        exit 1
      fi
    fi
  done
}

# strip the release version off the end of
build::go::download "${GO_BIN_VERSION}" "$OUTPUT_DIR" "$ARCHITECTURE"
