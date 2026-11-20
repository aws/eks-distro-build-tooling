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

set -x
set -e
set -o pipefail

DOWNLOAD_DIR="$1"
VERSIONS="${2:-}"
OUTPUT=/golang-versions

TARGETARCH=${TARGETARCH:-amd64}

mkdir -p $OUTPUT

if [ -z "$VERSIONS" ]; then
  echo "No extra golang versions to install"
  exit 0
fi

for version in ${VERSIONS//,/ }; do
  release=${version%-*}
  minor=${release%.*}

  # Stage one version at a time because install_golang.sh deletes every tarball in /tmp/linux/$TARGETARCH.
  mkdir -p /tmp/linux/$TARGETARCH
  mv $DOWNLOAD_DIR/linux/$TARGETARCH/go$release.linux-$TARGETARCH.tar.gz /tmp/linux/$TARGETARCH/
  /install_golang.sh $version

  # Build go-licenses from the final /root/sdk path because it records its GOROOT at build time.
  mv /golang-$minor/root/sdk /root/sdk
  PATH=/root/sdk/go$release/bin:$PATH /install_go_licenses.sh
  mv /root/sdk /golang-$minor/root/sdk

  cp -a --remove-destination /golang-$minor/. $OUTPUT/
  cp -a --remove-destination /go-licenses-$minor/. $OUTPUT/
  rm -rf /golang-$minor /go-licenses-$minor
done
