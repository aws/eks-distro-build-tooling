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

NEWROOT=/oras

source $SCRIPT_ROOT/common_vars.sh

ORAS_FILENAME="oras_${ORAS_VERSION}_linux_${TARGETARCH}.tar.gz"
ORAS_DOWNLOAD_URL="https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/${ORAS_FILENAME}"
ORAS_CHECKSUM_URL="https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_checksums.txt"

function install_oras() {
    wget \
        --progress dot:giga \
        $ORAS_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/oras-$TARGETARCH-checksum
    tar -xzvf $ORAS_FILENAME oras
    mv oras $USR_BIN/oras
    chmod +x $USR_BIN/oras
    rm -f $ORAS_FILENAME

    time upx --best --no-lzma $USR_BIN/oras
}

[ ${SKIP_INSTALL:-false} != false ] || (install_oras)
