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

TARGETARCH=${TARGETARCH:-amd64}
USR=${USR:-${NEWROOT}/usr}
USR_LOCAL=${USR_LOCAL:-${USR}/local}
USR_BIN=${USR}/bin
USR_LOCAL_BIN=${USR_LOCAL}/bin

BASE_DIR=""

IS_AL23=false
if [ -f /etc/yum.repos.d/amazonlinux.repo ] && grep -q "2023" /etc/yum.repos.d/amazonlinux.repo; then 
    IS_AL23=true
fi

[ ${SKIP_INSTALL:-false} != false ] || mkdir -p $USR_BIN $USR_LOCAL_BIN
