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
    # ansible-core 2.16 and later require Python 3.10 or newer.
    local -r deps="python3.11 python3.11-pip"
    yum install -y $deps
    local -r pip="python3.11 -m pip"
    local -r python_version="3.11"

    ANSIBLE_VERSION="$ANSIBLE_VERSION"
    $pip install --user --no-cache-dir "ansible-core==$ANSIBLE_VERSION"

    PYWINRM_VERSION="$PYWINRM_VERSION"
    $pip install --user --no-cache-dir "pywinrm==$PYWINRM_VERSION"
    
    rm -rf ${NEWROOT}/usr/*
    mv /root/.local/* ${NEWROOT}/usr

    chmod 755 ${NEWROOT}/usr/lib/python${python_version}/site-packages 

    # ansible-test is never run here and its pinned sanity requirement files trip image scans, see ansible/ansible#86459.
    rm -rf ${NEWROOT}/usr/lib/python${python_version}/site-packages/ansible_test ${NEWROOT}/usr/bin/ansible-test

    rm -rf /root/.cache
}

[ ${SKIP_INSTALL:-false} != false ] || instal_ansible
