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

NEWROOT=/ecr-cred-helper

source $SCRIPT_ROOT/common_vars.sh

AMAZON_ECR_CRED_HELPER_VERSION="${AMAZON_ECR_CRED_HELPER_VERSION:-0.6.0}"
AMAZON_ECR_CRED_HELPER_DOWNLOAD_URL="https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${AMAZON_ECR_CRED_HELPER_VERSION}/linux-$TARGETARCH/docker-credential-ecr-login"
AMAZON_ECR_CRED_HELPER_CHECKSUM_URL="${AMAZON_ECR_CRED_HELPER_DOWNLOAD_URL}.sha256"

function install_docker_cred() {
    wget \
        --progress dot:giga \
        $AMAZON_ECR_CRED_HELPER_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/amazon-ecr-cred-helper-$TARGETARCH-checksum
    mv docker-credential-ecr-login $USR_BIN/
    chmod +x $USR_BIN/docker-credential-ecr-login

    ls -al $USR_BIN
}

[ ${SKIP_INSTALL:-false} != false ] || install_docker_cred
