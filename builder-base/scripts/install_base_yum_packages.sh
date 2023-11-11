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

# since we are using the minimal-base-builder
# policycoreutils is only half installed and the rpm db
# is technically in an invalid state
# removing it to avoid issues in future rpm transactions
yum remove -y policycoreutils > /dev/null 2>&1

# keep rpms around since we use them in every stage
if [ "$IS_AL23" = "true" ]; then
    echo "keepcache=1" >> /etc/dnf/dnf.conf
    rm -rf /var/cache/dnf
    ln -s yum /var/cache/dnf
    rm -f /var/lib/dnf/history.*
else
    sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf
    yum history new
fi

yum install --setopt=install_weak_deps=False -y \
    gzip \
    tar \
    unzip \
    wget \
    xz

chmod -R 777 /newroot
rm -rf /newroot
