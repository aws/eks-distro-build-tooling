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

NEWROOT=/linuxkit

source $SCRIPT_ROOT/common_vars.sh


function install_linuxkit() {
    # linuxkit is used by tinkerbell/hook for building an operating system installation environment (osie)
    # We need a higher version of linuxkit hence we do go install of a particular commit
    CGO_ENABLED=0  GO111MODULE=on GOBIN=${GOPATH}/go1.19/bin ${GOPATH}/go1.19/bin/go install github.com/linuxkit/linuxkit/src/cmd/linuxkit@$LINUXKIT_VERSION

    mv ${GOPATH}/go1.19/bin/linuxkit ${USR_BIN}/linuxkit

    rm -rf ${GOPATH}

    time upx --best --no-lzma ${USR_BIN}/linuxkit
}

[ ${SKIP_INSTALL:-false} != false ] || install_linuxkit
