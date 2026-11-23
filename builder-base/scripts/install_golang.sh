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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

VERSION="$1"

GOLANG_MAJOR_VERSION=$(if [[ $(echo "$VERSION" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${VERSION%.*}; else echo ${VERSION%-*}; fi)

NEWROOT=/golang-${GOLANG_MAJOR_VERSION}

source $SCRIPT_ROOT/common_vars.sh

mkdir -p /go/src /go/bin /go/pkg

function build::go::symlink() {
  local -r version=$1

  # Removing the last number as we only care about the major version of golang
  local -r majorversion=$(if [[ $(echo "$version" | awk -F'.' '{print NF}') -ge 3 ]]; then echo ${version%.*}; else echo ${version%-*}; fi)
  mkdir -p ${GOPATH}/go${majorversion}/bin

  for binary in go gofmt; do
    ln -s /root/sdk/go${version}/bin/${binary} ${GOPATH}/go${majorversion}/bin/${binary}
  done

  if [ "$version" != "$majorversion" ]; then
    ln -s ${GOPATH}/bin/go${version} ${GOPATH}/bin/go${majorversion}
  fi
}

function build::go::install {
  # Set up specific go version by using go get, additional versions apart from default can be installed by calling
  # the function again with the specific parameter.
  local version=${1%-*}
  build::go::extract $version
  build::go::symlink $version
}

function build::go::extract {
  local version=$1
  local major_version=$(echo "$version" | cut -d. -f1)
  local minor_version=$(echo "$version" | cut -d. -f2)

  mkdir -p /tmp/go-extracted
  cd /tmp/go-extracted
  tar -xzf /tmp/linux/$TARGETARCH/go$version.linux-$TARGETARCH.tar.gz

  # go stopped building addr2line, doc, objdump, pprof, and trace by default starting with 1.25 so building them here
  if [[ "$major_version" -eq 1 && "$minor_version" -ge 25 ]]; then
      local binaries=("addr2line" "objdump" "pprof" "trace")
      # cmd/doc was removed in Go 1.26: https://go.dev/doc/go1.26#tools
      if [[ "$minor_version" -lt 26 ]]; then
          binaries+=("doc")
      fi
      pushd /tmp/go-extracted/go/
      for binary in "${binaries[@]}"; do
        bin/go build -o "pkg/tool/linux_$TARGETARCH/$binary" "./src/cmd/$binary"
      done
      popd
  fi

  local -r golang_version=$(/tmp/go-extracted/go/bin/go version | grep -o "go[0-9].* " | xargs)

  mkdir -p /root/sdk/$golang_version
  mv /tmp/go-extracted/go/* /root/sdk/$golang_version

  version=$(echo "$golang_version" | grep -o "[0-9].*")
  ln -s /root/sdk/go${version}/bin/go ${GOPATH}/bin/$golang_version

  rm -rf /tmp/go-extracted /tmp/linux/$TARGETARCH/go*.tar.gz
}

build::go::install "${VERSION}"

# symlink default golang install to newroot bin
for binary in go gofmt; do
  ln -s ${GOPATH}/go${GOLANG_MAJOR_VERSION}/bin/${binary} ${USR_BIN}/${binary}
done

mkdir -p ${NEWROOT}/root
mv /root/sdk ${NEWROOT}/root
mv ${GOPATH} ${NEWROOT}/${GOPATH}

# not upx'ing link + compile since they are often times running conncurrently
# accoriding to the upx docs, this can increase memory usage, ref:
# Currently, executables compressed by UPX do not share RAM at runtime
#   in the way that executables mapped from a file system do.  As a
#   result, if the same program is run simultaneously by more than one
#   process, then using the compressed version will require more RAM and/or
#   swap space.  So, shell programs (bash, csh, etc.)  and ``make''
#   might not be good candidates for compression.
UPX_TOOLS=(addr2line asm cgo cover objdump pprof trace vet)
MINOR=$(echo "${VERSION%-*}" | cut -d. -f2)
if [[ "$MINOR" -lt 26 ]]; then
  UPX_TOOLS+=(doc)
fi
time upx --best --no-lzma ${NEWROOT}/root/sdk/go${VERSION%-*}/bin/go $(printf "${NEWROOT}/root/sdk/go${VERSION%-*}/pkg/tool/linux_$TARGETARCH/%s " "${UPX_TOOLS[@]}")
