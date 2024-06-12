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
source $SCRIPT_ROOT/common_vars.sh

uname -a

docker-credential-ecr-login -v
yq --version
gh --version
govc version
helm version
docker buildx version
buildctl --version
aws --version
bash --version
7zz

if [ $TARGETARCH == 'amd64' ]; then 
    hugo version
    # goss
fi

tuftool --help
skopeo --version

# node + go + gcc are only included in the standard image
if [ "${FINAL_STAGE_BASE}" = "full-copy-stage" ]; then
    python --version
    python3 --version
    pip3 --version
    packer --version
    ansible --version
    su - imagebuilder -c "ansible --version"
    su - imagebuilder -c "ansible-galaxy collection list"
    su - imagebuilder -c "packer --version"
    su - imagebuilder -c "packer plugins installed"

    node --version

    # validate default symlinks are correctly setup
    go version
    go-licenses --help
    
    linuxkit version
    /go/bin/go1.17 version
    /go/go1.17/bin/go-licenses --help
    /go/bin/go1.18 version
    /go/go1.18/bin/go-licenses --help
    /go/bin/go1.19 version
    /go/go1.19/bin/go-licenses --help
    /go/bin/go1.20 version
    /go/go1.20/bin/go-licenses --help
    /go/bin/go1.21 version
    /go/go1.21/bin/go-licenses --help

    gcc --version

    notation plugin list
fi
