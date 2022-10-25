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

NEWROOT=/tuftool

source $SCRIPT_ROOT/common_vars.sh

RUSTUP_DOWNLOAD_URL="https://sh.rustup.rs"


function install_tuftool() {
    local -r deps="openssl openssl-devel"
    yum install -y $deps

    # Installing Tuftool for Bottlerocket downloads
    curl -fsS $RUSTUP_DOWNLOAD_URL | CARGO_HOME=$CARGO_HOME RUSTUP_HOME=$RUSTUP_HOME sh -s -- -y
    find $CARGO_HOME/bin -type f -not -name "cargo" -not -name "rustc" -not -name "rustup" -delete
    $CARGO_HOME/bin/rustup default stable
    CARGO_NET_GIT_FETCH_WITH_CLI=true $CARGO_HOME/bin/cargo install --force -v --root $CARGO_HOME tuftool 
    cp $CARGO_HOME/bin/tuftool $USR_BIN/tuftool

    rm -rf $RUSTUP_HOME $CARGO_HOME
}

[ ${SKIP_INSTALL:-false} != false ] || install_tuftool
