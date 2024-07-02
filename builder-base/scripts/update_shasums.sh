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
CHECKSUMS_ROOT="$SCRIPT_ROOT/.."

eval $(yq e 'to_entries | .[] | [.key,.value] | join("=") ' versions.yaml)

for TARGETARCH in arm64 amd64; do
  source $SCRIPT_ROOT/versions.sh

  # YQ
  yq_checksum_order=($(curl -sSL --retry 5 $YQ_CHECKSUM_ORDER_URL))
  yq_checksums=$(curl -sSL --retry 5 -v --silent $YQ_CHECKSUM_URL)
  yq_checksums=$(echo "$yq_checksums" | grep yq_linux_$TARGETARCH.tar.gz | cut -d ":" -f 2)
  IFS=' ' read -r -a yq_checksums_ar <<<"$yq_checksums"

  yq_checksum_index=-1
  for i in "${!yq_checksum_order[@]}"; do
    if [[ "${yq_checksum_order[$i]}" = "SHA-256" ]]; then
      yq_checksum_index=$(($i + 1))
    fi
  done
  echo $yq_checksum_index
  echo "${yq_checksums_ar[*]}"
  sha256="${yq_checksums_ar[$yq_checksum_index]}"
  echo "$sha256  yq_linux_$TARGETARCH.tar.gz" >$CHECKSUMS_ROOT/checksums/yq-$TARGETARCH-checksum

  # AMAZON_ECR_CRED_HELPER
  curl -sSL --retry 5 $AMAZON_ECR_CRED_HELPER_CHECKSUM_URL -o $CHECKSUMS_ROOT/checksums/amazon-ecr-cred-helper-$TARGETARCH-checksum

  # BUILDKIT
  sha256=$(curl -sSL --retry 5 $BUILDKIT_DOWNLOAD_URL | sha256sum | awk '{print $1}')
  echo "$sha256  buildkit-$BUILDKIT_VERSION.linux-$TARGETARCH.tar.gz" >$CHECKSUMS_ROOT/checksums/buildkit-$TARGETARCH-checksum

  # GITHUB CLI
  echo "$(curl -sSL --retry 5 -v --silent $GITHUB_CLI_CHECKSUM_URL 2>&1 | grep gh_${GITHUB_CLI_VERSION}_linux_$TARGETARCH.tar.gz | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/github-cli-$TARGETARCH-checksum

  # PACKER
  echo "$(curl -sSL --retry 5 -v --silent $PACKER_CHECKSUM_URL 2>&1 | grep packer_${PACKER_VERSION}_linux_$TARGETARCH.zip | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/packer-$TARGETARCH-checksum

  # NODEJS
  echo "$(curl -sSL --retry 5 -v --silent $NODEJS_CHECKSUM_URL 2>&1 | grep $NODEJS_FILENAME | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/nodejs-$TARGETARCH-checksum

  # HELM
  sha256=$(curl -sSL --retry 5 $HELM_CHECKSUM_URL)
  echo "$sha256  helm-v${HELM_VERSION}-linux-$TARGETARCH.tar.gz" >$CHECKSUMS_ROOT/checksums/helm-$TARGETARCH-checksum

  # GOLANG
  #go_active_version=$(curl https://go.dev/dl/?mode=json | jq -r '.[].version' | sed -e "s/^$GO_PREFIX//" | sort)
  #for v in $go_active_version; do
  #  go_major_version=$(if [[ $(echo "$v" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${v%.*}; else echo ${v%-*}; fi)
  #  sha256=$(curl -sSLf --retry 5 "https://go.dev/dl/?mode=json" | jq -r --arg tar "go$version.linux-${TARGETARCH/\//-}.tar.gz" '.[].files[] | if .filename == $tar then .sha256 else "" end' | xargs)
  #  echo "$sha256" >"$CHECKSUMS_ROOT/checksums/go-$go_major_version-$TARGETARCH-checksum"
  #done

  # GOVC
  echo "$(curl -sSL --retry 5 -v $GOVC_CHECKSUM_URL 2>&1 | grep $GOVC_FILENAME | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/govc-$TARGETARCH-checksum

  # GOSS
  echo "$(curl -sSL --retry 5 -v --silent $GOSS_CHECKSUM_URL 2>&1 | grep packer-provisioner-goss-v${GOSS_VERSION}-linux-$TARGETARCH.tar.gz | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/goss-$TARGETARCH-checksum

  # UPX
  sha256=$(curl -sSL --retry 5 $UPX_DOWNLOAD_URL | sha256sum | awk '{print $1}')
  echo "$sha256  upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz" >$CHECKSUMS_ROOT/checksums/upx-$TARGETARCH-checksum

  # Notation
  echo "$(curl -sSL --retry 5 -v $NOTATION_CHECKSUM_URL 2>&1 | grep $NOTATION_FILENAME | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/notation-$TARGETARCH-checksum

  # Oras
  echo "$(curl -sSL --retry 5 -v $ORAS_CHECKSUM_URL 2>&1 | grep $ORAS_FILENAME | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/oras-$TARGETARCH-checksum

  # 7zip
  sha256=$(curl -sSL --retry 5 $SEVENZIP_DOWNLOAD_URL | sha256sum | awk '{print $1}')
  echo "$sha256  7z${SEVENZIP_VERSION//./}-linux-${ARCH}.tar.xz" >$CHECKSUMS_ROOT/checksums/7zip-$TARGETARCH-checksum
done

# HUGO
echo "$(curl -sSL --retry 5 -v --silent $HUGO_CHECKSUM_URL 2>&1 | grep $HUGO_FILENAME | cut -d ":" -f 2)" >$CHECKSUMS_ROOT/checksums/hugo-$TARGETARCH-checksum

# BASH
sha256=$(curl -sSL --retry 5 $BASH_DOWNLOAD_URL | sha256sum | awk '{print $1}')
echo "$sha256  bash-$OVERRIDE_BASH_VERSION.tar.gz" >$CHECKSUMS_ROOT/checksums/bash-checksum
