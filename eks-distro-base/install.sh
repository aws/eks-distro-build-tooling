#!/usr/bin/env bash
# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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
set -x

amazon-linux-extras enable docker
yum install -y \
    awscli \
    amazon-ecr-credential-helper \
    git \
    make \
    openssh-clients \
    tar \
    wget \

BUILDKIT_VERSION="${BUILDKIT_VERSION:-v0.7.2}"
wget --progress dot:giga https://github.com/moby/buildkit/releases/download/$BUILDKIT_VERSION/buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz
sha256sum -c builder-base/buildkit-checksum
tar -C /usr -xzf buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz
rm -rf buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz

GITHUB_CLIENT_VERSION="${GITHUB_CLIENT_VERSION:-1.2.1}"
wget --progress dot:giga https://github.com/cli/cli/releases/download/v1.2.1/gh_1.2.1_linux_amd64.tar.gz
sha256sum -c eks-distro-base/github_cli_checksum
tar -xzf gh_${GITHUB_CLIENT_VERSION}_linux_amd64.tar.gz
mv gh_${GITHUB_CLIENT_VERSION}_linux_amd64/bin/gh /usr/bin
rm -rf gh_${GITHUB_CLIENT_VERSION}_linux_amd64.tar.gz
