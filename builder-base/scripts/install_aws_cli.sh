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

NEWROOT=/aws-cli

source $SCRIPT_ROOT/common_vars.sh


function install_aws_cli() {
    if [ $TARGETARCH == 'amd64' ]; then 
        ARCH='x86_64'
    else 
        ARCH='aarch64'
    fi

    wget \
        --progress dot:giga \
        https://awscli.amazonaws.com/awscli-exe-linux-$ARCH.zip
    unzip -qq awscli-exe-linux-$ARCH.zip
    ./aws/install 
    aws --version

    # install symlinks so we cant install directly to our overridden usr/local
    if [ "$USR_LOCAL" != "/usr/local" ]; then
        mv /usr/local/aws-cli $USR_LOCAL
        mv /usr/local/bin/{aws,aws_completer} $USR_LOCAL_BIN
    fi
    
    rm awscli-exe-linux-$ARCH.zip
    rm -rf aws
}

[ ${SKIP_INSTALL:-false} != false ] || install_aws_cli
