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

NEWROOT=/yq

source $SCRIPT_ROOT/common_vars.sh

YQ_VERSION="${YQ_VERSION:-v4.24.5}"
YQ_DOWNLOAD_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_$TARGETARCH.tar.gz"
YQ_CHECKSUM_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums"
YQ_CHECKSUM_ORDER_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums_hashes_order"


function install_yq() {
    # needed to parse eks-d release yaml to get latest artifacts
    wget \
        --progress dot:giga \
        $YQ_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/yq-$TARGETARCH-checksum
    tar -C $USR_BIN -xzf yq_linux_$TARGETARCH.tar.gz
    mv $USR_BIN/yq_linux_$TARGETARCH $USR_BIN/yq
}

[ ${SKIP_INSTALL:-false} != false ] || install_yq
