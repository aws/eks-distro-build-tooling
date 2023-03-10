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

PATCHING_TOOLS="$(git rev-parse --show-toplevel)/projects/golang/go/development/scripts/patches/lib/patch.sh"
source "$PATCHING_TOOLS"

# * VERSION_DIR:  absolute path to the Golang minor version directory under this repo's projects/golang/go,
#                 e.g. ~/go/eks-distro-build-tooling/projects/golang/go/1.16
#
# * GOLANG_DIR:   the absolute path to the root directory of the Golang repo, which must be cloned locally,
#                 must be up-to-date with upstream, and must not be "dirty".
#
# * APPLY_CVE_PATCHES:  "true" if CVE patches should be applied. All other values are interpreted as "false".
#                        Minor versions supported by upstream are not presumed to have any CVE patches. CVE
#                        patch files must start with ####-go-1.XX.YY-eks-..., with 1.XX.YY the Go version.
#
# * APPLY_OTHER_PATCHES:  "true" if non-CVE patches should be applied. All other values are interpreted as
#                         "false". Other patch files must NOT include the Golang version at the start.
VERSION_DIR=$(realpath "$1")
GOLANG_DIR=$(realpath "$2")
if [ "$3" == "" ]; then
    echo "Please specify a commit to cherry-pick"
    exit 1
fi
CHERRY_PICK_COMMIT=$3

clone_golang "$GOLANG_DIR"
checkout_golang_at_git_tag "$VERSION_DIR" "$GOLANG_DIR"

apply_cve_patches "$VERSION_DIR" "$GOLANG_DIR"
cherry_pick "$GOLANG_DIR" "$CHERRY_PICK_COMMIT"
apply_other_patches "$VERSION_DIR" "$GOLANG_DIR"
