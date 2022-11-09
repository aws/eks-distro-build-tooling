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

if [ "$1" == "" ]; then
  echo "Please specify a Go Minor Version to set up for EKS Go"
  exit 1
fi
GOLANG_MINOR_VERSION=$1

BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/golang/go/"
VERSION_DIRECTORY="${PROJECT_DIRECTORY}${GOLANG_MINOR_VERSION}"

GOLANG_GIT_TAG=$(cat $VERSION_DIRECTORY/GIT_TAG)
GOLANG_RELEASE=$(cat $VERSION_DIRECTORY/RELEASE)

touch ${VERSION_DIRECTORY}/README.md

cat >${VERSION_DIRECTORY}/README.md <<EOF
# EKS Golang ${GOLANG_MINOR_VERSION}

Current Release: \`${GOLANG_RELEASE}\`

Tracking Tag: \`${GOLANG_GIT_TAG}\`

Artifacts: https://distro.eks.amazonaws.com/golang-go${GOLANG_MINOR_VERSION}/releases/${GOLANG_RELEASE}/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-${GOLANG_MINOR_VERSION}-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)
bro
### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-${GOLANG_MINOR_VERSION}-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in \`./patches\` include relevant utility fixes for go \`${GOLANG_MINOR_VERSION}\`.

### Spec
The RPM spec file in \`./rpmbuild/SPECS\` is sourced from the go ${GOLANG_MINOR_VERSION} SRPM available on Fedora, and modified to include the relevant patches and build the \`${GOLANG_GIT_TAG}\` source.

EOF
