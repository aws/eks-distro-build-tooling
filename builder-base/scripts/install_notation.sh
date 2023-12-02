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

NEWROOT=/notation

source $SCRIPT_ROOT/common_vars.sh

NOTATION_FILENAME="notation_${NOTATION_VERSION}_linux_${TARGETARCH}.tar.gz"
NOTATION_DOWNLOAD_URL="https://github.com/notaryproject/notation/releases/download/v${NOTATION_VERSION}/${NOTATION_FILENAME}"
NOTATION_CHECKSUM_URL="https://github.com/notaryproject/notation/releases/download/v${NOTATION_VERSION}/notation_${NOTATION_VERSION}_checksums.txt"

NOTATION_AWS_SIGNER_PLUGIN_ZIP_FILENAME="notation-aws-signer-plugin.zip"
NOTATION_AWS_SIGNER_PLUGIN_URL="https://d2hvyiie56hcat.cloudfront.net/linux/${TARGETARCH}/plugin/latest/${NOTATION_AWS_SIGNER_PLUGIN_ZIP_FILENAME}"
NOTATION_AWS_SIGNER_PLUGIN_DIRECTORY="$NEWROOT/root/.config/notation/plugins/com.amazonaws.signer.notation.plugin"
NOTATION_AWS_SIGNER_PLUGIN_BINARY="notation-com.amazonaws.signer.notation.plugin"

function install_notation() {
    wget \
        --progress dot:giga \
        $NOTATION_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/notation-$TARGETARCH-checksum
    tar -xzvf $NOTATION_FILENAME notation
    mv notation $USR_BIN/notation
    chmod +x $USR_BIN/notation
    rm -f $NOTATION_FILENAME

    time upx --best --no-lzma $USR_BIN/notation
}

function install_aws_signer_plugin() {
    wget \
        --progress dot:giga \
        $NOTATION_AWS_SIGNER_PLUGIN_URL
    unzip $NOTATION_AWS_SIGNER_PLUGIN_ZIP_FILENAME
    mkdir -p $NOTATION_AWS_SIGNER_PLUGIN_DIRECTORY
    mv $NOTATION_AWS_SIGNER_PLUGIN_BINARY $NOTATION_AWS_SIGNER_PLUGIN_DIRECTORY
    chmod +x $NOTATION_AWS_SIGNER_PLUGIN_DIRECTORY/$NOTATION_AWS_SIGNER_PLUGIN_BINARY
    rm LICENSE THIRD_PARTY_LICENSES $NOTATION_AWS_SIGNER_PLUGIN_ZIP_FILENAME
}

[ ${SKIP_INSTALL:-false} != false ] || (install_notation && install_aws_signer_plugin)
