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
    curl \
    gcc \
    git \
    jq \
    less \
    make \
    man \
    procps-ng \
    python3-pip \
    rsync \
    tar \
    unzip \
    vim \
    wget \
    which

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
aws --version

GOLANG_VERSION="${GOLANG_VERSION:-1.15.6}"
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

# Bash 4.3 is required to run kubernetes make test
OVERRIDE_BASH_VERSION="${OVERRIDE_BASH_VERSION:-4.3}"
wget http://ftp.gnu.org/gnu/bash/bash-$OVERRIDE_BASH_VERSION.tar.gz 
tar -xf bash-$OVERRIDE_BASH_VERSION.tar.gz
sha256sum -c $BASE_DIR/bash-checksum

cd bash-$OVERRIDE_BASH_VERSION
./configure --prefix=/usr --without-bash-malloc
make 
make install 
cd ..
rm -f bash-$OVERRIDE_BASH_VERSION.tar.gz
rm -rf bash-$OVERRIDE_BASH_VERSION

# directory setup
mkdir -p /go/src /go/bin /go/pkg /go/src/github.com/aws/eks-distro

# install additional versions of go
export GOPATH=/go
export PATH=${GOPATH}/bin/:$PATH

# Set up specific go version by using go get, additional versions apart from default can be installed by calling
# the function again with the specific parameter.
setupgo() {
    local -r version=$1
    go get golang.org/dl/go${version}
    go${version} download
    # Removing the last number as we only care about the major version of golang
    local -r majorversion=${version%.*}
    mkdir -p ${GOPATH}/go${majorversion}/bin
    cp ${GOPATH}/bin/go${version} ${GOPATH}/go${majorversion}/bin/go
}

setupgo "${GOLANG113_VERSION:-1.13.15}"
setupgo "${GOLANG114_VERSION:-1.14.13}"
setupgo "${GOLANG115_VERSION:-1.15.6}"

# install amazon-ecr-credential-helper
# We are installing a specific commit of this because we need the sts regional endpoint changes in the aws sdk
# to avoid hitting the global sts endpoint.
# Commit: https://github.com/awslabs/amazon-ecr-credential-helper/commit/a004738dbac968cb287b47ae8ca39fd3b451e547
git clone https://github.com/awslabs/amazon-ecr-credential-helper.git
cd amazon-ecr-credential-helper
git checkout a004738dbac968cb287b47ae8ca39fd3b451e547
make
cp bin/local/docker-credential-ecr-login /usr/bin/
cd ..
rm -rf amazon-ecr-credential-helper
