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

NEWROOT=/upx

source $SCRIPT_ROOT/common_vars.sh

UPX_DOWNLOAD_URL="https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz"

function install_upx() {
    wget --progress dot:giga $UPX_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/upx-$TARGETARCH-checksum
    tar -xf upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz
    mv upx-${UPX_VERSION}-${TARGETARCH}_linux/upx ${NEWROOT}/usr/local/bin
    rm -rf upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz upx-${UPX_VERSION}-${TARGETARCH}_linux/upx
}

[ ${SKIP_INSTALL:-false} != false ] || install_upx
