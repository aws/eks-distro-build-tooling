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

NEWROOT=/ansible

source $SCRIPT_ROOT/common_vars.sh

function instal_ansible() {
    if [ "$IS_AL23" = "true" ]; then 
        local -r deps="python3-pip"
        yum install -y $deps
    else
        pip3 install --no-cache-dir -U pip setuptools
    fi

    ANSIBLE_VERSION="$ANSIBLE_VERSION"
    pip3 install --user --no-cache-dir "ansible-core==$ANSIBLE_VERSION"

    PYWINRM_VERSION="$PYWINRM_VERSION"
    pip3 install --user --no-cache-dir "pywinrm==$PYWINRM_VERSION"
    
    rm -rf ${NEWROOT}/usr/*
    mv /root/.local/* ${NEWROOT}/usr

    if [ "$IS_AL23" = "false" ]; then 
        # pulling only the python folders/bin we need
        # follows list from minimal image Dockerfile.minimal-base-python
        mkdir -p $NEWROOT/usr/lib/pkgconfig ${NEWROOT}/usr/{bin,include}
        cp /usr/bin/{pip3,pip3.9,pydoc3.9,python3,python3.9,python3.9-config} ${NEWROOT}/usr/bin
        cp -rf /usr/include/python3.9 ${NEWROOT}/usr/include
        cp /usr/lib/pkgconfig/python-3.9*.pc ${NEWROOT}/usr/lib/pkgconfig
        cp -rf /usr/lib/python3.9 ${NEWROOT}/usr/lib
        cp --preserve=links /usr/lib/libpython3* ${NEWROOT}/usr/lib
    fi

    rm -rf /root/.cache
}

[ ${SKIP_INSTALL:-false} != false ] || instal_ansible
