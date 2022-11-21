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

NEWROOT=/docker_buildx

source $SCRIPT_ROOT/common_vars.sh


DOCKER_BUILDX_URL="https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/buildx-$DOCKER_BUILDX_VERSION.linux-$TARGETARCH"
DOCKER_BUILDX_CHECKSUM_URL="https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/checksums.txt"


function install_docker_buildx() {
    wget \
        --progress dot:giga \
        $DOCKER_BUILDX_URL
    sha256sum -c $BASE_DIR/docker-buildx-$TARGETARCH-checksum
    mkdir -p ${NEWROOT}/root/.docker/cli-plugins
    mv buildx-$DOCKER_BUILDX_VERSION.linux-$TARGETARCH ${NEWROOT}/root/.docker/cli-plugins/docker-buildx
    chmod a+x ${NEWROOT}/root/.docker/cli-plugins/docker-buildx
}

[ ${SKIP_INSTALL:-false} != false ] || install_docker_buildx
