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

function update::go::version {
  local -r version=$1
  local -r majorversion=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)

  local -r cur_builder_base_version=$(cat "${VERSIONS_YAML}" | grep -E "^GOLANG_VERSION_${majorversion//./}")

  sed -i "s/${cur_builder_base_version}/GOLANG_VERSION_${majorversion//./}: ${version}/g" "${VERSIONS_YAML}"
}

# curl go.dev for the supported versions of go
ACTIVE_VERSIONS=$(curl https://go.dev/dl/?mode=json | jq -r '.[].version' | sed -e "s/^$GO_PREFIX//" | sort)

# pull golang versions in the versions.yaml
BUILDER_BASE_GO_VERSION=$(cat "${VERSIONS_YAML}" | grep -E "^GOLANG_VERSION_[0-9]{3}")

for v in ${ACTIVE_VERSIONS}; do
  # check builder-base versions for the upstream version of golang
  # if the version doesn't exist in the builder base update the versions yaml.
  if [[ ! $BUILDER_BASE_GO_VERSION =~ $v ]]; then
    update::go::version $v
  fi
done
