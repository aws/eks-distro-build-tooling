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

NEWROOT=/helm

source $SCRIPT_ROOT/common_vars.sh

HELM_VERSION="${HELM_VERSION:-3.8.1}"
HELM_DOWNLOAD_URL="https://get.helm.sh/helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz"
HELM_CHECKSUM_URL="$HELM_DOWNLOAD_URL.sha256"


function install_helm() {
    # Installing Helm
    wget \
        --progress dot:giga \
        $HELM_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/helm-$TARGETARCH-checksum
    tar -xzvf helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz linux-$TARGETARCH/helm
    mv linux-$TARGETARCH/helm $USR_BIN/helm
    chmod +x $USR_BIN/helm
    rm -f helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz
}

[ ${SKIP_INSTALL:-false} != false ] || install_helm
