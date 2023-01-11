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

VERSION=$(go version | grep -o "go[0-9].* ")
GOLANG_MAJOR_VERSION=${VERSION%.*}

NEWROOT=/go-licenses-${GOLANG_MAJOR_VERSION#go}

source $SCRIPT_ROOT/common_vars.sh

function install_go_licenses() {

    # installing go-licenses has to happen after we have set the main go
    # to symlink to the one in /root/sdk to ensure go-licenses gets built
    # with GOROOT pointed to /root/sdk/go... instead of /usr/local/go so it
    # is able to properly packages from the standard Go library
    # We currently  use 1.19, 1.17 or 1.16, so installing for all
    if [ "${GOLANG_MAJOR_VERSION}" = "go1.16" ]; then
        GO111MODULE=on GOBIN=${NEWROOT}/${GOPATH}/${GOLANG_MAJOR_VERSION}/bin go install github.com/jaxesn/go-licenses@4497a2a38565e4e6ad095ea8117c25ecd622d0cc
    else
        GO111MODULE=on GOBIN=${NEWROOT}/${GOPATH}/${GOLANG_MAJOR_VERSION}/bin go install github.com/jaxesn/go-licenses@6800d77c11d0ef8628e7eda908b1d1149383ca48
    fi

    # symlink to go/bin and depending on which go-licenses vs is added last to
    # the final image, will take precedent and be the default
    # similiar to the strategy with golang
    mkdir -p ${NEWROOT}/${GOPATH}/bin
    ln -s ${GOPATH}/${GOLANG_MAJOR_VERSION}/bin/go-licenses ${NEWROOT}/${GOPATH}/bin/go-licenses
    
    rm -rf ${GOPATH}
}

[ ${SKIP_INSTALL:-false} != false ] || install_go_licenses
