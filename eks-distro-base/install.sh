#!/usr/bin/env bash
# Install/setup script for EKS distro base image

set -e
set -o pipefail
set -x

amazon-linux-extras enable docker
yum install -y \
    awscli \
    amazon-ecr-credential-helper \
    git \
    make \
    openssh \
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
tar -C /usr -xzf gh_${GITHUB_CLIENT_VERSION}_linux_amd64.tar.gz
rm -rf gh_${GITHUB_CLIENT_VERSION}_linux_amd64.tar.gz

eval "$(ssh-agent -s)"
ssh-add /secrets/ssh/ssh-secret/ssh-privatekey
ssh -o StrictHostKeyChecking=no git@github.com;
