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

NEWROOT=/7zip

source $SCRIPT_ROOT/common_vars.sh

if [ $TARGETARCH == 'amd64' ]; then 
    ARCH='x64'
else 
    ARCH='arm64'
fi

SEVENZIP_DOWNLOAD_URL="https://github.com/ip7z/7zip/releases/download/${SEVENZIP_VERSION}/7z${SEVENZIP_VERSION//.}-linux-${ARCH}.tar.xz"

function install_7zip() {
    wget \
        --progress dot:giga \
        $SEVENZIP_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/7zip-$TARGETARCH-checksum
    tar -C $USR_BIN -xJf 7z${SEVENZIP_VERSION//.}-linux-${ARCH}.tar.xz 7zz License.txt

    time upx --best --no-lzma $USR_BIN/7zz
}

[ ${SKIP_INSTALL:-false} != false ] || install_7zip
