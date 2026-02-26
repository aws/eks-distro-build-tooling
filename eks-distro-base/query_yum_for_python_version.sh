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

set -x
set -o errexit
set -o nounset
set -o pipefail

PYTHON_VERSION="$1"
AL_TAG="$2"


if [ "$AL_TAG" = "2023" ]; then
    MIRROR=$(curl -s https://cdn.amazonlinux.com/al2023/core/mirrors/latest/debuginfo/x86_64/mirror.list | sed 's:/$::')
    VERSION=$(curl -sS ${MIRROR}/repodata/primary.xml.gz | gunzip | sed -rn "s/^.*python${PYTHON_VERSION}-debuginfo-(.*)\-[0-9].amzn.*$/\1/p" | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//' | tail -1)
else
    MIRROR=$(curl -s http://amazonlinux.default.amazonaws.com/2/core/latest/debuginfo/x86_64/mirror.list | sed 's:/$::')
    VERSION=$(curl -sS $MIRROR/repodata/primary.xml.gz | gunzip | sed -rn "s/^.*python3-debuginfo-(.*)\-[0-9].amzn.*$/\1/p" | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//' | tail -1)
fi

if [ -f /etc/os-release ] && grep "Amazon Linux 2" /etc/os-release; then
    if [ "$(yum info python3  | grep "^Version" | cut -d: -f2 | xargs)" != "$VERSION" ]; then
        echo "Yum version does not match curl'd!"
        exit 1
    fi
fi

echo $VERSION
