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
source $SCRIPT_ROOT/common_vars.sh

uname -a

docker-credential-ecr-login -v
yq --version
gh --version
govc version
helm version
docker buildx version
buildctl --version
aws --version
bash --version
7zz

if [ $TARGETARCH == 'amd64' ]; then
  hugo version
  # goss
fi

tuftool --help
skopeo --version

# node + go + gcc are only included in the standard image
if [ "${FINAL_STAGE_BASE}" = "full-copy-stage" ]; then
  python --version
  python3 --version
  pip3 --version
  packer --version
  ansible --version
  su - imagebuilder -c "ansible --version"
  su - imagebuilder -c "ansible-galaxy collection list"
  su - imagebuilder -c "packer --version"
  su - imagebuilder -c "packer plugins installed"

  node --version

  # validate default symlinks are correctly setup
  go version
  default_release=${GOLANG_DEFAULT_VERSION:?GOLANG_DEFAULT_VERSION is not set}
  default_release=${default_release%-*}
  if ! go version | grep -q "go$default_release "; then
    echo "default go is not go$default_release"
    exit 1
  fi
  go-licenses --help

  linuxkit version
  if [ -z "${GOLANG_VERSIONS}" ]; then
    echo "GOLANG_VERSIONS is not set"
    exit 1
  fi
  for version in ${GOLANG_VERSIONS//,/ }; do
    release=${version%-*}
    minor=${release%.*}
    /go/bin/go$minor version
    /go/go$minor/bin/go-licenses --help

    # A stdlib-only module must report only itself when go-licenses classifies the standard library correctly.
    module=$(mktemp -d)
    cp /root/sdk/go$release/LICENSE $module/
    printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println() }\n' > $module/main.go
    licenses=$(cd $module && export PATH=/go/go$minor/bin:$PATH GOTOOLCHAIN=local GOCACHE=$module/cache && \
      go mod init example.com/stdlib-only && go-licenses csv .)
    rm -rf $module
    if [ -z "$licenses" ]; then
      echo "go-licenses for go$minor reported no packages"
      exit 1
    fi
    if echo "$licenses" | grep -v -e '^example.com/stdlib-only,' -e '^$'; then
      echo "go-licenses for go$minor reports standard library packages"
      exit 1
    fi
  done

  gcc --version

  notation plugin list
fi
