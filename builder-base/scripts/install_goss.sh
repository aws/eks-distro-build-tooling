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

NEWROOT=/goss

source $SCRIPT_ROOT/common_vars.sh

GOSS_DOWNLOAD_URL="https://github.com/YaleUniversity/packer-provisioner-goss/releases/download/v${GOSS_VERSION}/packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz"
GOSS_CHECKSUM_URL="https://github.com/YaleUniversity/packer-provisioner-goss/releases/download/v${GOSS_VERSION}/packer-provisioner-goss-v${GOSS_VERSION}_SHA256SUMS"

function install_goss() {
    mkdir -p /goss/home/imagebuilder/.packer.d/plugins

    if [ $TARGETARCH == 'arm64' ]; then
        # there is no build for arm
        return
    fi

    # Installing Goss for imagebuilder validation    
    wget \
        --progress dot:giga \
        $GOSS_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/goss-$TARGETARCH-checksum
    tar -C ${NEWROOT}/home/imagebuilder/.packer.d/plugins -xzf packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz
    rm -rf packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz
}

[ ${SKIP_INSTALL:-false} != false ] || install_goss
