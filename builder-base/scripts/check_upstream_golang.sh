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

GO_PREFIX="go"
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VERSIONS_YAML="${SCRIPT_ROOT}/../versions.yaml"
TAG_FILE="${SCRIPT_ROOT}/../../EKS_DISTRO_TAG_FILE.yaml"

function update::go::version {
  local -r version=$1
  local -r majorversion=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)

  local -r cur_builder_base_version=$(cat "${VERSIONS_YAML}" | grep -E "^GOLANG_VERSION_${majorversion//./}")

  sed -i "s/${cur_builder_base_version}/GOLANG_VERSION_${majorversion//./}: ${version}-0/g" "${VERSIONS_YAML}"
}

function add::go::version {
  local -r version=$1
  local -r majorversion=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)

  echo "GOLANG_VERSION_${majorversion//./}: $version-0" >>$VERSIONS_YAML
}

# Using YQ allows us to modify the existing tag or add the correct tag if it doesn't exist
function modify::go::minimal_image {
  local -r version=$1
  local -r majorversion=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)

  # AL2 updates
  AL2BASE=".al2.[\"eks-distro-minimal-base-golang-compiler-${majorversion}-base\"]" yq 'eval(strenv(AL2BASE)) = null' -i $TAG_FILE
  AL2YUM=".al2.[\"eks-distro-minimal-base-golang-compiler-${majorversion}-yum\"]" yq 'eval(strenv(AL2YUM)) = null' -i $TAG_FILE
  AL2GCC=".al2.[\"eks-distro-minimal-base-golang-compiler-${majorversion}-gcc\"]" yq 'eval(strenv(AL2GCC)) = null' -i $TAG_FILE

  # AL2023 updates
  AL2023BASE=".al2023.[\"eks-distro-minimal-base-golang-compiler-${majorversion}-base\"]" yq 'eval(strenv(AL2023BASE)) = null' -i $TAG_FILE
  AL2023YUM=".al2023.[\"eks-distro-minimal-base-golang-compiler-${majorversion}-yum\"]" yq 'eval(strenv(AL2023YUM)) = null' -i $TAG_FILE
  AL2023GCC=".al2023.[\"eks-distro-minimal-base-golang-compiler-${majorversion}-gcc\"]" yq 'eval(strenv(AL2023GCC)) = null' -i $TAG_FILE
}

# curl go.dev for the supported versions of go
ACTIVE_VERSIONS=$(curl https://go.dev/dl/?mode=json | jq -r '.[].version' | sed -e "s/^$GO_PREFIX//" | sort)

for version in ${ACTIVE_VERSIONS}; do
  # pull golang versions in the versions.yaml
  MAJORVERSION=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)
  BUILDER_BASE_GO_VERSION=$(cat "${VERSIONS_YAML}" | grep -E "^GOLANG_VERSION_${MAJORVERSION//./}") || echo ""
  # check builder-base versions for the upstream version of golang
  # if the version doesn't exist in the builder base update the versions yaml.
  if [[ -n $BUILDER_BASE_GO_VERSION && ! $BUILDER_BASE_GO_VERSION =~ $version ]]; then
    update::go::version $version
    modify::go::minimal_image $version
  elif [[ -z $BUILDER_BASE_GO_VERSION ]]; then
    add::go::version $version
    modify::go::minimal_image $version
  fi
done

${SCRIPT_ROOT}/update_shasums.sh
