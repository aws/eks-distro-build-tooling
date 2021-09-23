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

# This script is used to install the necessary dependencies on the pod
# building the builder-base as well as into the builder-base itself
# Note: since we run the build in fargate we do not have access to an overlayfs
# so we use a single script from the dockerfile instead of layers to avoid
# layer duplicate and running out of disk space 
# This does make local builds painful.  Its recommended to add new additions
# in their own script/layer while testing and then when you are done add 
# to here

set -e
set -o pipefail
set -x
shopt -s extglob

echo "Running install.sh in $(pwd)"
BASE_DIR=""
if [[ "$CI" == "true" ]]; then
    BASE_DIR=$(pwd)/builder-base
fi

# Only add dependencies needed to build the builder base in this first part
yum upgrade -y
yum update -y

amazon-linux-extras enable docker
yum install -y \
    amazon-ecr-credential-helper \
    git \
    make \
    tar \
    unzip \
    wget

GOLANG_VERSION="${GOLANG_VERSION:-1.16.7}"
wget \
    --progress dot:giga \
    --max-redirect=1 \
    --domains golang.org \
    https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
sha256sum -c $BASE_DIR/golang-checksum
tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
rm go${GOLANG_VERSION}.linux-amd64.tar.gz
mv /usr/local/go/bin/* /usr/bin/

# go-licenses doesnt have any release tags, using the latest master
# intentionally installing this very early to catch if goproxy is going to be issue
# such if running in a an env where proxy.golang.org is blocked
GO111MODULE=on go get github.com/google/go-licenses@v0.0.0-20210816172045-3099c18c36e1

wget \
    --progress dot:giga \
    https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip awscli-exe-linux-x86_64.zip
./aws/install
aws --version
rm awscli-exe-linux-x86_64.zip
rm -rf /aws

BUILDKIT_VERSION="${BUILDKIT_VERSION:-v0.9.0}"
wget \
    --progress dot:giga \
    https://github.com/moby/buildkit/releases/download/$BUILDKIT_VERSION/buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz
sha256sum -c $BASE_DIR/buildkit-checksum
tar -C /usr -xzf buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz
rm -rf buildkit-$BUILDKIT_VERSION.linux-amd64.tar.gz

GITHUB_CLI_VERSION="${GITHUB_CLI_VERSION:-1.8.0}"
wget --progress dot:giga https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
sha256sum -c $BASE_DIR/github-cli-checksum
tar -xzf gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
mv gh_${GITHUB_CLI_VERSION}_linux_amd64/bin/gh /usr/bin
rm -rf gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz gh_${GITHUB_CLI_VERSION}_linux_amd64

if [[ "$CI" == "true" ]]; then
    exit
fi

# Add any additional dependencies we want in the builder-base image here

# directory setup
mkdir -p /go/src /go/bin /go/pkg /go/src/github.com/aws/eks-distro

yum install -y \
    bind-utils \
    curl \
    docker \
    gcc \
    gettext \
    jq \
    less \
    openssh-clients \
    procps-ng \
    python3-pip \
    rsync \
    vim \
    which

# Install image-builder build dependencies
# Post upgrade, pip3 got renamed to pip and moved locations. It works completely with python3
# Symlinking pip3 to pip, to have pip3 commands work successfully
pip3 install -U pip setuptools
ln -sf /usr/local/bin/pip /usr/bin/pip3
ANSIBLE_VERSION="${ANSIBLE_VERSION:-2.10.0}"
pip3 install "ansible==$ANSIBLE_VERSION"

PYWINRM_VERSION="${PYWINRM_VERSION:-0.4.1}"
pip3 install "pywinrm==$PYWINRM_VERSION"

PACKER_VERSION="${PACKER_VERSION:-1.7.2}"
rm -rf /usr/sbin/packer
wget \
    --progress dot:giga \
    https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_linux_amd64.zip
sha256sum -c $BASE_DIR/packer-checksum
unzip -o packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/bin
rm -rf packer_${PACKER_VERSION}_linux_amd64.zip

useradd -ms /bin/bash -u 1100 imagebuilder
mkdir -p /home/imagebuilder/.packer.d/plugins
GOSS_VERSION="${GOSS_VERSION:-3.0.3}"
wget \
    --progress dot:giga \
    https://github.com/YaleUniversity/packer-provisioner-goss/releases/download/v${GOSS_VERSION}/packer-provisioner-goss-v${GOSS_VERSION}-linux-amd64.tar.gz
sha256sum -c $BASE_DIR/goss-checksum
tar -C /home/imagebuilder/.packer.d/plugins -xzf packer-provisioner-goss-v${GOSS_VERSION}-linux-amd64.tar.gz
rm -rf packer-provisioner-goss-v${GOSS_VERSION}-linux-amd64.tar.gz

GOVC_VERSION="${GOVC_VERSION:-0.24.0}"
wget \
    --progress dot:giga \
    https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/govc_linux_amd64.gz
sha256sum -c $BASE_DIR/govc-checksum
gzip -d govc_linux_amd64.gz
mv govc_linux_amd64 /usr/bin/govc
chmod +x /usr/bin/govc

# needed to parse eks-d release yaml to get latest artifacts
YQ_VERSION="${YQ_VERSION:-v4.7.1}"
wget \
    --progress dot:giga \
    https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz
sha256sum -c $BASE_DIR/yq-checksum
tar -xzf yq_linux_amd64.tar.gz
mv yq_linux_amd64 /usr/bin/yq
rm yq_linux_amd64.tar.gz

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

# Set up specific go version by using go get, additional versions apart from default can be installed by calling
# the function again with the specific parameter.
setupgo() {
    local -r version=$1
    go get golang.org/dl/go${version}
    go${version} download
    # Removing the last number as we only care about the major version of golang
    local -r majorversion=${version%.*}
    mkdir -p ${GOPATH}/go${majorversion}/bin
    ln -s ${GOPATH}/bin/go${version} ${GOPATH}/go${majorversion}/bin/go
    ln -s /root/sdk/go${version}/bin/gofmt ${GOPATH}/go${majorversion}/bin/gofmt
    # Removing the source code and other files from GOROOT for each version
    rm -rf /root/sdk/${version}/!(bin/pkg)
}

setupgo "${GOLANG113_VERSION:-1.13.15}"
setupgo "${GOLANG114_VERSION:-1.14.15}"
setupgo "${GOLANG115_VERSION:-1.15.14}"
setupgo "${GOLANG116_VERSION:-1.16.7}"
GOLANG_LATEST_MAJOR="1.16"

shopt -u extglob

# use the go installed using go get
rm -rf /usr/local/go /usr/bin/go /usr/bin/gofmt
ln -s ${GOPATH}/go${GOLANG_LATEST_MAJOR}/bin/go /usr/bin/go
ln -s ${GOPATH}/go${GOLANG_LATEST_MAJOR}/bin/gofmt /usr/bin/gofmt

# Install hugo for docs
HUGOVERSION=0.85.0
wget https://github.com/gohugoio/hugo/releases/download/v${HUGOVERSION}/hugo_extended_${HUGOVERSION}_Linux-64bit.tar.gz
sha256sum -c ${BASE_DIR}/hugo-checksum
tar -xf hugo_extended_${HUGOVERSION}_Linux-64bit.tar.gz
mv hugo /usr/bin/hugo
rm -rf hugo_extended_${HUGOVERSION}_Linux-64bit.tar.gz LICENSE README.md

NODEJS_VERSION="${NODEJS_VERSION:-v15.11.0}" 
wget --progress dot:giga \
    https://nodejs.org/dist/$NODEJS_VERSION/node-$NODEJS_VERSION-linux-x64.tar.gz
sha256sum -c ${BASE_DIR}/nodejs-checksum
tar -C /usr --strip-components=1 -xzf node-$NODEJS_VERSION-linux-x64.tar.gz node-$NODEJS_VERSION-linux-x64
rm -rf node-$NODEJS_VERSION-linux-x64.tar.gz

cd /opt/generate-attribution
ln -s $(pwd)/generate-attribution /usr/bin/generate-attribution
npm install

yum clean all
rm -rf /var/cache/yum
go clean --modcache
# go get leaves the tar around
find /root/sdk -type f -name 'go*.tar.gz' -delete
# pip cache
rm -rf /root/.cache
# Removing doc and man files
find /usr/share/{doc,man} -type f \
    ! \( -iname '*lice*' -o -iname '*copy*' -o -iname '*gpl*' -o -iname '*not*' -o -iname "*credits*" \) \
    -delete
