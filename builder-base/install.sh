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
CARGO_HOME=/root/.cargo
RUSTUP_HOME=/root/.rustup

echo "Running install.sh in $(pwd)"
BASE_DIR=""
if [[ "$CI" == "true" ]]; then
    BASE_DIR=$(pwd)/builder-base
fi

IS_AL22=false
if [ -f /etc/yum.repos.d/amazonlinux.repo ] && grep -q "2022" /etc/yum.repos.d/amazonlinux.repo; then 
    IS_AL22=true
fi

source $BASE_DIR/versions.sh

function build::go::symlink() {
    local -r version=$1

    # Removing the last number as we only care about the major version of golang
    local -r majorversion=${version%.*}
    mkdir -p ${GOPATH}/go${majorversion}/bin
    for binary in go gofmt; do
        ln -s /root/sdk/go${version}/bin/${binary} ${GOPATH}/go${majorversion}/bin/${binary}
    done
    ln -s ${GOPATH}/bin/go${version} ${GOPATH}/bin/go${majorversion}
}

function build::go::install(){
    # Set up specific go version by using go get, additional versions apart from default can be installed by calling
    # the function again with the specific parameter.
    local version=$1

    # AL2 provides a longer supported version of golang, use AL2 package when possible
    local yum_provided_versions="1.13"
    local eks_built_versions="1.16.15 1.15.15 1.17.13"
    if [[ $eks_built_versions =~ (^|[[:space:]])${version}($|[[:space:]]) && $TARGETARCH == "amd64" && $IS_AL22 == false ]]; then
        local arch='x86_64'
        local golang_release=1
        for artifact in golang golang-bin golang-race; do
          curl https://distro.eks.amazonaws.com/golang-go$version/releases/$golang_release/RPMS/$arch/$artifact-$version-$golang_release.amzn2.eks.$arch.rpm -o /tmp/$artifact-$version-$golang_release.amzn2.eks.$arch.rpm
        done

        for artifact in golang-docs golang-misc golang-tests golang-src; do
          curl https://distro.eks.amazonaws.com/golang-go$version/releases/$golang_release/RPMS/noarch/$artifact-$version-$golang_release.amzn2.eks.noarch.rpm -o /tmp/$artifact-$version-$golang_release.amzn2.eks.noarch.rpm
        done

        build::go::extract $version
    elif [[ $yum_provided_versions =~ (^|[[:space:]])${version%.*}($|[[:space:]]) ]]; then
        # Do not install rpm directly instead follow eks-distro base images pattern
        # of downloading and install rpms directly
        for package in golang golang-bin golang-docs golang-misc golang-src golang-tests golang-race; do
            # arm al22 does not provide golang-race
            if [[ $(yum --showduplicates list $package) ]]; then
                al2_package_version=$(yum --showduplicates list $package | awk -F ' ' '{print $2}' | grep ${version%.*} | tail -n 1)
                yumdownloader --destdir=/tmp -x "*.i686" $package-$al2_package_version
            fi
        done
        build::go::extract $version
    else
        go install golang.org/dl/go${version}@latest
        go${version} download
    fi

    build::go::symlink $version
}

function build::go::extract() {
      local version=$1
      mkdir -p /tmp/go-extracted
      for rpm in /tmp/golang-*.rpm; do $(cd /tmp/go-extracted && rpm2cpio $rpm | cpio -idmv); done

      local -r golang_version=$(/tmp/go-extracted/usr/lib/golang/bin/go version | grep -o "go[0-9].* " | xargs)

      mkdir -p /root/sdk/$golang_version
      mv /tmp/go-extracted/usr/lib/golang/* /root/sdk/$golang_version

      if [ "$IS_AL22" = true ]; then
          mv /tmp/go-extracted/usr/share/licenses/golang/* /root/sdk/$golang_version
      else
          mv /tmp/go-extracted/usr/share/doc/golang-*/* /root/sdk/$golang_version
      fi

      version=$(echo "$golang_version" | grep -o "[0-9].*")
      ln -s /root/sdk/go${version}/bin/go ${GOPATH}/bin/$golang_version

      rm -rf /tmp/go-extracted /tmp/golang-*.rpm
}

function build::cleanup(){
    yum clean all
    rm -rf /var/cache/{amzn2extras,yum,ldconfig}
    
    # truncate logs
    find /var/log -type f | while read file; do echo -ne '' > $file; done

    # Removing doc and man files
    # to get all symlinks run twice
    for i in {1..2}; do
        find /usr/share/{doc,man} \( -xtype l -o -type f \) \
            ! \( -iname '*lice*' -o -iname '*copy*' -o -iname '*gpl*' -o -iname '*not*' -o -iname "*credits*" \) \
            -delete
    done
    find /usr/share/{doc,man} -type d -empty -delete

    # go get leaves the tar around
    find /root/sdk -type f -name 'go*.tar.gz' -delete
    go clean --modcache
    
    # pip cache
    rm -rf /root/.cache

    # rust docs
    rm -rf /root/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/doc

    # cargo cache
    if command -v cargo-cache &> /dev/null; then
        cargo-cache  --remove-dir all
    fi
}


yum install -y \
    git-core \
    make \
    tar \
    unzip \
    wget

wget \
    --progress dot:giga \
    $AMAZON_ECR_CRED_HELPER_DOWNLOAD_URL
sha256sum -c $BASE_DIR/amazon-ecr-cred-helper-$TARGETARCH-checksum
mv docker-credential-ecr-login $USR_BIN/
chmod +x $USR_BIN/docker-credential-ecr-login

GOLANG_MAJOR_VERSION=${GOLANG_VERSION%.*}

GOLANG_SDK_ROOT=/root/sdk/go${GOLANG_VERSION}
mkdir -p ${GOLANG_SDK_ROOT}
wget \
    --progress dot:giga \
    --max-redirect=1 \
    --domains go.dev \
    $GOLANG_DOWNLOAD_URL -O go${GOLANG_VERSION}.linux-$TARGETARCH.tar.gz
sha256sum -c $BASE_DIR/golang-$TARGETARCH-checksum
tar -C ${GOLANG_SDK_ROOT} -xzf go${GOLANG_VERSION}.linux-$TARGETARCH.tar.gz --strip-components=1
for binary in go gofmt; do
    ln -s /root/sdk/go${GOLANG_VERSION}/bin/${binary} ${USR_BIN}/${binary}
done
mkdir -p ${GOPATH}/bin
ln -s /root/sdk/go${GOLANG_VERSION}/bin/go ${GOPATH}/bin/go${GOLANG_VERSION}
build::go::symlink ${GOLANG_VERSION}

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


# The base image is the kind-minimal image with a /etc/passwd file
# based from the minimal base, which is setup manually.  The root
# user's shell is configured as /sbin/nologin
# This doesnt work for the builder-base usage in Codebuild which runs 
# certain commands specifically as root.  We need the shell to be bash.
usermod --shell /bin/bash root

# directory setup
mkdir -p /go/src /go/bin /go/pkg /go/src/github.com/aws/eks-distro

yum install -y \
    bind-utils \
    cpio \
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
    patch \
    pkgconfig \
    procps-ng \
    python3-pip \
    rsync \
    vim \
    which \
    yum-utils

# needed to parse eks-d release yaml to get latest artifacts
wget \
    --progress dot:giga \
    $YQ_DOWNLOAD_URL
sha256sum -c $BASE_DIR/yq-$TARGETARCH-checksum
mv yq_linux_$TARGETARCH $USR_BIN/yq
chmod +x $USR_BIN/yq

if [ "$IS_AL22" = false ]; then
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
fi

build::go::install "${GOLANG119_VERSION:-1.19.1}"
build::go::install "${GOLANG117_VERSION:-1.17.13}"
build::go::install "${GOLANG116_VERSION:-1.16.15}"

build::cleanup

if [ $TARGETARCH == 'arm64' ]; then
    exit
fi

# Install image-builder build dependencies - pip, Ansible, Packer
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

# installing go-licenses has to happen after we have set the main go
# to symlink to the one in /root/sdk to ensure go-licenses gets built
# with GOROOT pointed to /root/sdk/go... instead of /usr/local/go so it
# is able to properly packages from the standard Go library
# We currently  use 1.19, 1.17 or 1.16, so installing for all
GO111MODULE=on GOBIN=${GOPATH}/go1.19/bin ${GOPATH}/go1.19/bin/go install github.com/google/go-licenses@v1.2.1
GO111MODULE=on GOBIN=${GOPATH}/go1.18/bin ${GOPATH}/go1.18/bin/go install github.com/google/go-licenses@v1.2.1 
GO111MODULE=on GOBIN=${GOPATH}/go1.17/bin ${GOPATH}/go1.17/bin/go install github.com/google/go-licenses@v1.2.1 
GO111MODULE=on GOBIN=${GOPATH}/go1.16/bin ${GOPATH}/go1.16/bin/go get github.com/google/go-licenses@v1.2.1
# 1.16 is the default so symlink it to /go/bin
ln -s ${GOPATH}/go1.16/bin/go-licenses ${GOPATH}/bin

# linuxkit is used by tinkerbell/hook for building an operating system installation environment (osie)
# We need a higher version of linuxkit hence we do go get of a particular commit
GO111MODULE=on GOBIN=${GOPATH}/go1.16/bin ${GOPATH}/go1.16/bin/go get github.com/linuxkit/linuxkit/src/cmd/linuxkit@v0.0.0-20210616134744-ccece6a4889e

build::cleanup

# Installing NodeJS to run attribution generation script
wget --progress dot:giga $NODEJS_DOWNLOAD_URL
sha256sum -c ${BASE_DIR}/nodejs-$TARGETARCH-checksum
tar -C /usr --strip-components=1 -xzf $NODEJS_FILENAME $NODEJS_FOLDER
rm -rf $NODEJS_FILENAME

# Installing attribution generation script
mkdir generate-attribution-file
mv package*.json generate-attribution generate-attribution-file.js LICENSE-2.0.txt generate-attribution-file
rm -rf /tests
cd generate-attribution-file
ln -s $(pwd)/generate-attribution $USR_BIN/generate-attribution
npm install
cd ..

# Installing Tuftool for Bottlerocket downloads
curl -fsS $RUSTUP_DOWNLOAD_URL | CARGO_HOME=$CARGO_HOME RUSTUP_HOME=$RUSTUP_HOME sh -s -- -y
find $CARGO_HOME/bin -type f -not -name "cargo" -not -name "rustc" -not -name "rustup" -delete
$CARGO_HOME/bin/rustup default stable
CARGO_NET_GIT_FETCH_WITH_CLI=true $CARGO_HOME/bin/cargo install --force --root $CARGO_HOME tuftool
cp $CARGO_HOME/bin/tuftool $USR_BIN/tuftool

# Cargo cache management tool
CARGO_NET_GIT_FETCH_WITH_CLI=true $CARGO_HOME/bin/cargo install --force --root $CARGO_HOME tuftool cargo-cache
cargo-cache  --remove-dir all

# Installing Helm
curl -O $HELM_DOWNLOAD_URL
sha256sum -c $BASE_DIR/helm-$TARGETARCH-checksum
tar -xzvf helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz linux-$TARGETARCH/helm
rm -f helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz
mv linux-$TARGETARCH/helm $USR_BIN/helm
chmod +x $USR_BIN/helm

# Since these verison is coming from yum do not supply patch version
build::go::install "${GOLANG113_VERSION:-1.13.15}"
build::go::install "${GOLANG115_VERSION:-1.15.15}"

build::go::install "${GOLANG114_VERSION:-1.14.15}"

# Installing Goss for imagebuilder validation
useradd -ms /bin/bash -u 1100 imagebuilder
mkdir -p /home/imagebuilder/.packer.d/plugins
wget \
    --progress dot:giga \
    $GOSS_DOWNLOAD_URL
sha256sum -c $BASE_DIR/goss-$TARGETARCH-checksum
tar -C /home/imagebuilder/.packer.d/plugins -xzf packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz
rm -rf packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz

# Installing govc CLI
wget \
    --progress dot:giga \
    $GOVC_DOWNLOAD_URL
sha256sum -c $BASE_DIR/govc-$TARGETARCH-checksum
gzip -d govc_linux_$TARGETARCH.gz
mv govc_linux_$TARGETARCH $USR_BIN/govc
chmod +x $USR_BIN/govc

# Installing Hugo for docs

wget $HUGO_DOWNLOAD_URL
sha256sum -c ${BASE_DIR}/hugo-$TARGETARCH-checksum
tar -xf hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz
mv hugo $USR_BIN/hugo
rm -rf hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz LICENSE README.md

# Installing Skopeo
SKOPEO_VERSION="${SKOPEO_VERSION:-v1.5.2}"
git clone https://github.com/containers/skopeo
cd skopeo
git checkout $SKOPEO_VERSION
make bin/skopeo
mv bin/skopeo $USR_BIN/skopeo
cd ..
rm -rf skopeo

build::cleanup
