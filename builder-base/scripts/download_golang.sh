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

VERSION="$1"
OUTPUT_DIR="$2"
ARCHITECTURE="$3"

source $SCRIPT_ROOT/common_vars.sh

function build::go::download {
  # Set up specific go version by using go get, additional versions apart from default can be installed by calling
  # the function again with the specific parameter.
  local version=${1%-*}
  local outputDir=${2}
  local archs=${3}

  for arch in ${archs/,/ }; do
    local filename="$outputDir/${arch}/go$version.${arch/\//-}.tar.gz"
    if [ ! -f $filename ]; then
      curl -sSLf --retry 5 "https://go.dev/dl/go$version.${arch/\//-}.tar.gz" -o $filename --create-dirs

      go_major_version=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)
      (cd $(dirname $filename) && sha256sum -c $SCRIPT_ROOT/../checksums/go-go$go_major_version-${arch##*/}-checksum)
    fi
  done
}

function download_golang {
  build::go::download "${VERSION}" "$OUTPUT_DIR" "$ARCHITECTURE"
}

[ ${SKIP_INSTALL:-false} != false ] || download_golang
