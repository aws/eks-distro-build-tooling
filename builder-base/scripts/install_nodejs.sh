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

NEWROOT=/nodejs

source $SCRIPT_ROOT/common_vars.sh

# Select Node.js version based on AL_TAG (similar to skopeo pattern)
if [ "$IS_AL23" = "true" ]; then
    NODEJS_VERSION=$NODEJS_VERSION_AL23
    CHECKSUM_FILE="nodejs-al23-$TARGETARCH-checksum"
else
    CHECKSUM_FILE="nodejs-$TARGETARCH-checksum"
fi

if [ $TARGETARCH == 'amd64' ]; then 
    NODEJS_FILENAME="node-$NODEJS_VERSION-linux-x64.tar.gz"
    NODEJS_FOLDER="node-$NODEJS_VERSION-linux-x64"
else
    NODEJS_FILENAME="node-$NODEJS_VERSION-linux-arm64.tar.gz"
    NODEJS_FOLDER="node-$NODEJS_VERSION-linux-arm64"
fi
NODEJS_DOWNLOAD_URL="https://nodejs.org/dist/$NODEJS_VERSION/$NODEJS_FILENAME"
NODEJS_CHECKSUM_URL="https://nodejs.org/dist/$NODEJS_VERSION/SHASUMS256.txt.asc"


function install_nodejs() {
    # Installing NodeJS to run attribution generation script
    wget --progress dot:giga $NODEJS_DOWNLOAD_URL
    sha256sum -c ${BASE_DIR}/$CHECKSUM_FILE
    tar -C $USR --strip-components=1 -xzf $NODEJS_FILENAME $NODEJS_FOLDER
    rm -rf $NODEJS_FILENAME
}

function install_generate_attribution() {
    # Installing attribution generation script
    mkdir ${NEWROOT}/generate-attribution-file
    mv /package*.json /generate-attribution /generate-attribution-file.js /LICENSE-2.0.txt ${NEWROOT}/generate-attribution-file
    
    cd ${NEWROOT}/generate-attribution-file
    ln -s /generate-attribution-file/generate-attribution $USR_BIN/generate-attribution

    ln -s /$USR_BIN/node /usr/bin/node
    $USR_BIN/npm install

    time upx --best --no-lzma $USR_BIN/node
}

[ ${SKIP_INSTALL:-false} != false ] || (install_nodejs && install_generate_attribution)
