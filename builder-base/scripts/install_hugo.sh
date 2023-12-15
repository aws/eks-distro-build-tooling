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

NEWROOT=/hugo

source $SCRIPT_ROOT/common_vars.sh

if [ $TARGETARCH == 'amd64' ]; then 
    HUGO_FILENAME="hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz"
else
    HUGO_FILENAME="hugo_extended_${HUGO_VERSION}_Linux-ARM64.tar.gz"
fi
HUGO_DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/$HUGO_FILENAME"
HUGO_CHECKSUM_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt"


function install_hugo() {
    if [ $TARGETARCH == 'amd64' ]; then 
        ARCH='64bit'
    else 
        ARCH='ARM64'
        # there is no extended build for arm
        return
    fi

    # Installing Hugo for docs
    wget --progress dot:giga $HUGO_DOWNLOAD_URL
    sha256sum -c ${BASE_DIR}/hugo-$TARGETARCH-checksum
    tar -xf hugo_extended_${HUGO_VERSION}_Linux-${ARCH}.tar.gz
    mv hugo $USR_BIN/hugo
    rm -rf hugo_extended_${HUGO_VERSION}_Linux-${ARCH}.tar.gz LICENSE README.md
}

[ ${SKIP_INSTALL:-false} != false ] || install_hugo
