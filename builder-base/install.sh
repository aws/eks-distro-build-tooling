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

TARGETARCH=${TARGETARCH:-amd64}
USR_BIN=/usr/bin
USR_LOCAL_BIN=/usr/local/bin

echo "Running install.sh in $(pwd)"
BASE_DIR=""
if [[ "$CI" == "true" ]]; then
    BASE_DIR=$(pwd)/builder-base
fi

source $BASE_DIR/versions.sh

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

GOLANG_MAJOR_VERSION=${GOLANG_VERSION%.*}
GOLANG_SDK_ROOT=/root/sdk/go${GOLANG_VERSION}
GOLANG_MAJOR_VERSION_BIN=${GOPATH}/go${GOLANG_MAJOR_VERSION}/bin
mkdir -p ${GOLANG_MAJOR_VERSION_BIN}
mkdir -p ${GOLANG_SDK_ROOT}
wget \
    --progress dot:giga \
    --max-redirect=1 \
    --domains go.dev \
    $GOLANG_DOWNLOAD_URL -O go${GOLANG_VERSION}.linux-$TARGETARCH.tar.gz
sha256sum -c $BASE_DIR/golang-$TARGETARCH-checksum
tar -C ${GOLANG_SDK_ROOT} -xzf go${GOLANG_VERSION}.linux-$TARGETARCH.tar.gz --strip-components=1
for binary in go gofmt; do
    for symlink_dest in ${USR_BIN} ${GOLANG_MAJOR_VERSION_BIN}; do
        ln -s /root/sdk/go${GOLANG_VERSION}/bin/${binary} ${symlink_dest}/${binary}
    done
done
rm go${GOLANG_VERSION}.linux-$TARGETARCH.tar.gz

if [ $TARGETARCH == 'amd64' ]; then 
    ARCH='x86_64'
else 
    ARCH='aarch64'
fi

wget \
    --progress dot:giga \
    https://awscli.amazonaws.com/awscli-exe-linux-$ARCH.zip
unzip awscli-exe-linux-$ARCH.zip
./aws/install
aws --version
rm awscli-exe-linux-$ARCH.zip
rm -rf /aws

if [ $TARGETARCH == 'amd64' ]; then
    wget \
        --progress dot:giga \
        $BUILDKIT_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/buildkit-$TARGETARCH-checksum
    tar -C /usr -xzf buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz
    rm -rf buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz

    wget --progress dot:giga $GITHUB_CLI_DOWNLOAD_URL
    sha256sum -c $BASE_DIR/github-cli-$TARGETARCH-checksum
    tar -xzf gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz
    mv gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH/bin/gh $USR_BIN
    rm -rf gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH
fi

if [[ "$CI" == "true" ]]; then
    exit
fi

# Add any additional dependencies we want in the builder-base image here

# directory setup
mkdir -p /go/src /go/bin /go/pkg /go/src/github.com/aws/eks-distro

yum install -y \
    bind-utils \
    curl \
    device-mapper-devel \
    docker \
    gcc \
    gettext \
    gpgme-devel \
    jq \
    less \
    libassuan-devel \
    openssh-clients \
    openssl \
    openssl-devel \
    pkgconfig \
    procps-ng \
    python3-pip \
    rsync \
    vim \
    which

# needed to parse eks-d release yaml to get latest artifacts
wget \
    --progress dot:giga \
    $YQ_DOWNLOAD_URL
sha256sum -c $BASE_DIR/yq-$TARGETARCH-checksum
mv yq_linux_$TARGETARCH $USR_BIN/yq
chmod +x $USR_BIN/yq

# Bash 4.3 is required to run kubernetes make test
wget $BASH_DOWNLOAD_URL
tar -xf bash-$OVERRIDE_BASH_VERSION.tar.gz
sha256sum -c $BASE_DIR/bash-checksum
cd bash-$OVERRIDE_BASH_VERSION
./configure --prefix=/usr --without-bash-malloc
make
make install
cd ..
rm -f bash-$OVERRIDE_BASH_VERSION.tar.gz
rm -rf bash-$OVERRIDE_BASH_VERSION

yum clean all
rm -rf /var/cache/{amzn2extras,yum,ldconfig}
find /var/log -type f | while read file; do echo -ne '' > $file; done
# Removing doc and man files
find /usr/share/{doc,man} -type f \
    ! \( -iname '*lice*' -o -iname '*copy*' -o -iname '*gpl*' -o -iname '*not*' -o -iname "*credits*" \) \
    -delete


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
}

setupgo "${GOLANG117_VERSION:-1.17.5}"

if [ $TARGETARCH == 'arm64' ]; then
    exit
fi

# Install image-builder build dependencies
# Post upgrade, pip3 got renamed to pip and moved locations. It works completely with python3
# Symlinking pip3 to pip, to have pip3 commands work successfully
pip3 install -U pip setuptools
ln -sf $USR_LOCAL_BIN/pip $USR_BIN/pip3
ANSIBLE_VERSION="${ANSIBLE_VERSION:-2.10.0}"
pip3 install "ansible==$ANSIBLE_VERSION"

PYWINRM_VERSION="${PYWINRM_VERSION:-0.4.1}"
pip3 install "pywinrm==$PYWINRM_VERSION"

rm -rf /usr/sbin/packer
wget \
    --progress dot:giga \
    $PACKER_DOWNLOAD_URL
sha256sum -c $BASE_DIR/packer-$TARGETARCH-checksum
unzip -o packer_${PACKER_VERSION}_linux_$TARGETARCH.zip -d $USR_BIN
rm -rf packer_${PACKER_VERSION}_linux_$TARGETARCH.zip

# go-licenses doesnt have any release tags, using the latest master
# installing go-licenses has to happen after we have set the main go
# to symlink to the one in /root/sdk due to ensure go-licenses gets built
# with goroot pointed to /root/sdk/go... instead of /usr/local/go to its able
# to properly find core go packages
GO111MODULE=on go get github.com/google/go-licenses@v0.0.0-20210816172045-3099c18c36e1

# linuxkit is used by tinkerbell/hook for building an operating system installation environment (osie)
# We need a higher version of linuxkit hence we do go get of a particular commit
go get github.com/linuxkit/linuxkit/src/cmd/linuxkit@v0.0.0-20210616134744-ccece6a4889e

wget --progress dot:giga $NODEJS_DOWNLOAD_URL
sha256sum -c ${BASE_DIR}/nodejs-$TARGETARCH-checksum
tar -C /usr --strip-components=1 -xzf $NODEJS_FILENAME $NDOEJS_FOLDER
rm -rf $NODEJS_FILENAME

curl -O $HELM_DOWNLOAD_URL
sha256sum -c $BASE_DIR/helm-$TARGETARCH-checksum
tar -xzvf helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz linux-$TARGETARCH/helm
rm -f helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz
mv linux-$TARGETARCH/helm $USR_BIN/helm
chmod +x $USR_BIN/helm

cd /opt/generate-attribution
ln -s $(pwd)/generate-attribution $USR_BIN/generate-attribution
npm install


setupgo "${GOLANG113_VERSION:-1.13.15}"
setupgo "${GOLANG114_VERSION:-1.14.15}"
setupgo "${GOLANG115_VERSION:-1.15.15}"

useradd -ms /bin/bash -u 1100 imagebuilder
mkdir -p /home/imagebuilder/.packer.d/plugins
wget \
    --progress dot:giga \
    $GOSS_DOWNLOAD_URL
sha256sum -c $BASE_DIR/goss-$TARGETARCH-checksum
tar -C /home/imagebuilder/.packer.d/plugins -xzf packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz
rm -rf packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz

wget \
    --progress dot:giga \
    $GOVC_DOWNLOAD_URL
sha256sum -c $BASE_DIR/govc-$TARGETARCH-checksum
gzip -d govc_linux_$TARGETARCH.gz
mv govc_linux_$TARGETARCH $USR_BIN/govc
chmod +x $USR_BIN/govc

# Install hugo for docs

wget $HUGO_DOWNLOAD_URL
sha256sum -c ${BASE_DIR}/hugo-$TARGETARCH-checksum
tar -xf hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz
mv hugo $USR_BIN/hugo
rm -rf hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz LICENSE README.md

SKOPEO_VERSION="${SKOPEO_VERSION:-v1.5.0}"
git clone https://github.com/containers/skopeo
cd skopeo
git checkout $SKOPEO_VERSION
make bin/skopeo
mv bin/skopeo $USR_BIN/skopeo
cd ..
rm -rf skopeo

# go get leaves the tar around
find /root/sdk -type f -name 'go*.tar.gz' -delete
go clean --modcache
# pip cache
rm -rf /root/.cache
