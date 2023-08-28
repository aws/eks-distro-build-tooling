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
set -o errexit
set -o nounset
set -o pipefail

MAKE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

GOLANG_VERSION="$1"
GO_OS="$2"
GO_ARCH="$3"
GIT_VERSION="$4"
BINARY_NAME="$5"

echo ${MAKE_ROOT}

source "${MAKE_ROOT}/scripts/gobuildversion.sh"

build::common::use_go_version $GOLANG_VERSION

go build -ldflags "-X github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/version.gitVersion=${GIT_VERSION} -s -w -extldflags -static" -o bin/${GO_OS}/${GO_ARCH}/${BINARY_NAME} github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/cmd/${BINARY_NAME}
