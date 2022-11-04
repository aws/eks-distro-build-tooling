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

NEWROOT=/packer

source $SCRIPT_ROOT/common_vars.sh

PACKER_VERSION="${PACKER_VERSION:-1.7.2}"
PACKER_DOWNLOAD_URL="https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_linux_$TARGETARCH.zip"
PACKER_CHECKSUM_URL="https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_SHA256SUMS"

function install_packer() {
    # put packer in /usr/local/bin so it takes precedent
    # over the /usr/sbin/packer which is supplied by the cracklib package
    wget \
        --progress dot:giga \
        $PACKER_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/packer-$TARGETARCH-checksum
    unzip -o packer_${PACKER_VERSION}_linux_$TARGETARCH.zip -d $USR_LOCAL_BIN
}

[ ${SKIP_INSTALL:-false} != false ] || install_packer
