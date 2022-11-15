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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

NEWROOT=/gh-cli

source $SCRIPT_ROOT/common_vars.sh

GITHUB_CLI_DOWNLOAD_URL="https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz"
GITHUB_CLI_CHECKSUM_URL="https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_checksums.txt"

function install_gh_cli() {
    wget --progress dot:giga $GITHUB_CLI_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/github-cli-$TARGETARCH-checksum
    tar -xzf gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz
    mv gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH/bin/gh $USR_BIN
    rm -rf gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH
}

[ ${SKIP_INSTALL:-false} != false ] || install_gh_cli
