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
set -x

for TARGETARCH in arm64 amd64; do
    source ./versions.sh

    # GOLANG
    go_file_name="go$GOLANG_VERSION.linux-$TARGETARCH.tar.gz"
    sha256=$(curl -sSL --retry 5 https://go.dev/dl/?mode=json\&include=all | jq -r ".[] | select(.version==\"go$GOLANG_VERSION\") | .files[] | select(.filename==\"$go_file_name\").sha256")
    echo "$sha256  $go_file_name" > golang-$TARGETARCH-checksum

    # YQ
    readarray -t yq_checksum_order <<< $(curl -sSL --retry 5 $YQ_CHECKSUM_ORDER_URL)
    yq_checksums=$(curl -sSL --retry 5 $YQ_CHECKSUM_URL | grep -r yq_linux_$TARGETARCH | cut -d ":" -f 2)
    IFS=' ' read -r -a yq_checksums_ar <<< "$yq_checksums"

    yq_checksum_index=-1
    for i in "${!yq_checksum_order[@]}"; do
        if [[ "${yq_checksum_order[$i]}" = "SHA-256" ]]; then
            yq_checksum_index=$(($i+1))
        fi
    done
    echo $yq_checksum_index
    echo "${yq_checksums_ar[*]}"
    sha256="${yq_checksums_ar[$yq_checksum_index]}"
    echo "$sha256  yq_linux_$TARGETARCH" > yq-$TARGETARCH-checksum
done

# BUILDKIT
sha256=$(curl -sSL --retry 5 $BUILDKIT_DOWNLOAD_URL | sha256sum | awk '{print $1}')
echo "$sha256  buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz" > buildkit-$TARGETARCH-checksum

# GITHUB CLI
echo "$(curl -sSL --retry 5 $GITHUB_CLI_CHECKSUM_URL | grep -r gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz | cut -d ":" -f 2)" > github-cli-$TARGETARCH-checksum

# PACKER
echo "$(curl -sSL --retry 5 $PACKER_CHECKSUM_URL | grep -r packer_${PACKER_VERSION}_linux_$TARGETARCH.zip | cut -d ":" -f 2)" > packer-$TARGETARCH-checksum

# NODEJS
echo "$(curl -sSL --retry 5 $NODEJS_CHECKSUM_URL | grep -r $NODEJS_FILENAME | cut -d ":" -f 2)" > nodejs-$TARGETARCH-checksum

# HELM
sha256=$(curl -sSL --retry 5 $HELM_CHECKSUM_URL)
echo "$sha256  helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz" > helm-$TARGETARCH-checksum

# GOSS
# TODO: Later versions push a sha256sum file to github so when we upgrade we can start using it instead
sha256=$(curl -sSL --retry 5 $GOSS_DOWNLOAD_URL | sha256sum | awk '{print $1}')
echo "$sha256  packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz" > goss-$TARGETARCH-checksum

# GOVC
# TODO: Later versions push a sha256sum file to github so when we upgrade we can start using it instead
sha256=$(curl -sSL --retry 5 $GOVC_DOWNLOAD_URL | sha256sum | awk '{print $1}')
echo "$sha256  govc_linux_$TARGETARCH.gz" > govc-$TARGETARCH-checksum

# HUGO
echo "$(curl -sSL --retry 5 $HUGO_CHECKSUM_URL | grep -r $HUGO_FILENAME | cut -d ":" -f 2)" > hugo-$TARGETARCH-checksum

# BASH
sha256=$(curl -sSL --retry 5 $BASH_DOWNLOAD_URL | sha256sum | awk '{print $1}')
echo "$sha256  bash-$OVERRIDE_BASH_VERSION.tar.gz" > bash-checksum
