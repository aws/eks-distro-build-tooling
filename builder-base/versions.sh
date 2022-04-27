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

GOLANG_VERSION="${GOLANG_VERSION:-1.16.15}"
GOLANG_DOWNLOAD_URL="https://go.dev/dl/go$GOLANG_VERSION.linux-$TARGETARCH.tar.gz"

BUILDKIT_VERSION="${BUILDKIT_VERSION:-v0.10.1}"
BUILDKIT_DOWNLOAD_URL="https://github.com/moby/buildkit/releases/download/$BUILDKIT_VERSION/buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz"

GITHUB_CLI_VERSION="${GITHUB_CLI_VERSION:-1.8.0}"
GITHUB_CLI_DOWNLOAD_URL="https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz"
GITHUB_CLI_CHECKSUM_URL="https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_checksums.txt"

OVERRIDE_BASH_VERSION="${OVERRIDE_BASH_VERSION:-4.3}"
BASH_DOWNLOAD_URL="http://ftp.gnu.org/gnu/bash/bash-$OVERRIDE_BASH_VERSION.tar.gz"

PACKER_VERSION="${PACKER_VERSION:-1.7.2}"
PACKER_DOWNLOAD_URL="https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_linux_$TARGETARCH.zip"
PACKER_CHECKSUM_URL="https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_${PACKER_VERSION}_SHA256SUMS"

NODEJS_VERSION="${NODEJS_VERSION:-v15.11.0}"
if [ $TARGETARCH == 'amd64' ]; then 
    NODEJS_FILENAME="node-$NODEJS_VERSION-linux-x64.tar.gz"
    NDOEJS_FOLDER="node-$NODEJS_VERSION-linux-x64"
else
    NODEJS_FILENAME="node-$NODEJS_VERSION-linux-arm64.tar.gz"
    NDOEJS_FOLDER="node-$NODEJS_VERSION-linux-arm64"
fi
NODEJS_DOWNLOAD_URL="https://nodejs.org/dist/$NODEJS_VERSION/$NODEJS_FILENAME"
NODEJS_CHECKSUM_URL="https://nodejs.org/dist/$NODEJS_VERSION/SHASUMS256.txt"

HELM_VERSION="${HELM_VERSION:-3.8.1}"
HELM_DOWNLOAD_URL="https://get.helm.sh/helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz"
HELM_CHECKSUM_URL="$HELM_DOWNLOAD_URL.sha256"

GOSS_VERSION="${GOSS_VERSION:-3.0.3}"
GOSS_DOWNLOAD_URL="https://github.com/YaleUniversity/packer-provisioner-goss/releases/download/v${GOSS_VERSION}/packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz"
GOSS_CHECKSUM_URL="https://github.com/YaleUniversity/packer-provisioner-goss/releases/download/v${GOSS_VERSION}/packer-provisioner-goss-v${GOSS_VERSION}_SHA256SUMS"

GOVC_VERSION="${GOVC_VERSION:-0.24.0}"
GOVC_DOWNLOAD_URL="https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/govc_linux_$TARGETARCH.gz"
GOVC_CHECKSUM_URL="https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/checksums.txt"

HUGO_VERSION=0.85.0
if [ $TARGETARCH == 'amd64' ]; then 
    HUGO_FILENAME="hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz"
else
    HUGO_FILENAME="nhugo_extended_${HUGO_VERSION}_Linux-<nonexistent>.tar.gz"
fi
HUGO_DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/$HUGO_FILENAME"
HUGO_CHECKSUM_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt"


YQ_VERSION="${YQ_VERSION:-v4.7.1}"
YQ_DOWNLOAD_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_$TARGETARCH"
YQ_CHECKSUM_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums"
YQ_CHECKSUM_ORDER_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums_hashes_order"

AMAZON_ECR_CRED_HELPER_VERSION="${AMAZON_ECR_CRED_HELPER_VERSION:-0.6.0}"
AMAZON_ECR_CRED_HELPER_DOWNLOAD_URL="https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${AMAZON_ECR_CRED_HELPER_VERSION}/linux-$TARGETARCH/docker-credential-ecr-login"
AMAZON_ECR_CRED_HELPER_CHECKSUM_URL="${AMAZON_ECR_CRED_HELPER_DOWNLOAD_URL}.sha256"
