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

# Install script for builder-base

set -e
set -o pipefail
set -x

echo "Running install.sh in $(pwd)"
BASE_DIR=""
if [[ "$CI" == "true" ]]; then
    BASE_DIR=$(pwd)/builder-base
fi

yum upgrade -y
yum update -y

amazon-linux-extras enable docker
yum install -y \
    awscli \
    amazon-ecr-credential-helper \
    curl \
    git \
    jq \
    less \
    make \
    man \
    procps-ng \
    rsync \
    tar \
    vim \
    wget \
    which

GOLANG_VERSION="${GOLANG_VERSION:-1.13.15}"
wget \
    --progress dot:giga \
    --max-redirect=1 \
    --domains golang.org \
    https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
sha256sum -c $BASE_DIR/golang-checksum
tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
rm go${GOLANG_VERSION}.linux-amd64.tar.gz
mv /usr/local/go/bin/* /usr/bin/

BUILDKIT_VERSION="${BUILDKIT_VERSION:-v0.7.2}"
wget \
    --progress dot:giga \
    https://github.com/moby/buildkit/releases/download/$BUILDKIT_VERSION/buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz
sha256sum -c $BASE_DIR/buildkit-checksum
tar -C /usr -xzf buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz
rm -rf buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz

# directory setup
mkdir -p /go/src /go/bin /go/pkg /go/src/github.com/aws/eks-distro
