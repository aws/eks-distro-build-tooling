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

# This script is used to install the necessary dependencies on the pod
# building the builder-base as well as into the builder-base itself
# Note: since we run the build in fargate we do not have access to an overlayfs
# so we use a single script from the dockerfile instead of layers to avoid
# layer duplicate and running out of disk space
# This does make local builds painful.  Its recommended to add new additions
# in their own script/layer while testing and then when you are done add
# to here

set -e
set -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

NEWROOT=/buildkit

source $SCRIPT_ROOT/common_vars.sh

BUILDKIT_DOWNLOAD_URL="https://github.com/moby/buildkit/releases/download/$BUILDKIT_VERSION/buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz"


function install_buildkit() {
    wget \
        --progress dot:giga \
        $BUILDKIT_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/buildkit-$TARGETARCH-checksum
    tar -C $USR -xzf buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz
    rm -rf buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz
}

[ ${SKIP_INSTALL:-false} != false ] || install_buildkit
