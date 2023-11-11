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

NEWROOT=/govc

source $SCRIPT_ROOT/common_vars.sh

if [ $TARGETARCH == 'amd64' ]; then 
    ARCH='x86_64'
else 
    ARCH='arm64'
fi

GOVC_FILENAME="govc_Linux_$ARCH.tar.gz"
GOVC_DOWNLOAD_URL="https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/${GOVC_FILENAME}"
GOVC_CHECKSUM_URL="https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/checksums.txt"

function install_govc() {
    # Installing govc CLI
    wget \
        --progress dot:giga \
        $GOVC_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/govc-$TARGETARCH-checksum
    tar -xf govc_Linux_$ARCH.tar.gz
    mv govc $USR_BIN/govc
    chmod +x $USR_BIN/govc

    time upx --best --no-lzma $USR_BIN/govc
}

[ ${SKIP_INSTALL:-false} != false ] || install_govc
