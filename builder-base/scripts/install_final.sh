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

# The base image is the kind-minimal image with a /etc/passwd file
# based from the minimal base, which is setup manually.  The root
# user's shell is configured as /sbin/nologin
# This doesnt work for the builder-base usage in Codebuild which runs 
# certain commands specifically as root.  We need the shell to be bash.
usermod --shell /bin/bash root

# user for goss/imagebuilder
# to make sure the home dir is created correctly, tmp move the goss plugin
# on arm goss does not exist
if [ -f /home/imagebuilder/.packer.d/plugins/packer-provisioner-goss ]; then
    mv /home/imagebuilder/.packer.d/plugins/packer-provisioner-goss /tmp
fi

rm -rf /home/imagebuilder
useradd -ms /bin/bash -u 1100 imagebuilder

if [ -f /tmp/packer-provisioner-goss ]; then
    mkdir -p /home/imagebuilder/.packer.d/plugins/
    mv /tmp/packer-provisioner-goss /home/imagebuilder/.packer.d/plugins/
fi

# directory setup
mkdir -p /go/src/github.com/aws/eks-distro

yum install -y \
    bc \
    bind-utils \
    bzip2 \
    cpio \
    curl \
    docker \
    gettext \
    git-core \
    jq \
    less \
    make \
    openssh-clients \
    openssl \
    patch \
    procps-ng \
    rsync \
    tar \
    unzip \
    vim \
    wget \
    which \
    yum-utils

# We see issues in fargate when installing on top of these images
# including this plugin appears to fix it
# ref: https://unix.stackexchange.com/questions/348941/rpmdb-checksum-is-invalid-trying-to-install-gcc-in-a-centos-7-2-docker-image    
if [ "$IS_AL23" = "false" ]; then 
    yum install -y yum-plugin-ovl
fi

if [ "${FINAL_STAGE_BASE}" = "full-copy-stage" ]; then
    yum install -y \
        gcc \
        openssl-devel \
        pkgconfig \
        python3-pip

    # for building containerd
    yum install -y \
        glibc-static \
        libseccomp-static

    # headers for btrfs do not exist in al23. well need to address this in the future
    # if we want to build containerd with btrfs support on al23
    if [ "$IS_AL23" = "false" ]; then 
        yum install -y btrfs-progs-devel
    fi  
fi

#################### CLEANUP ####################
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

rm -rf /root/.cache
