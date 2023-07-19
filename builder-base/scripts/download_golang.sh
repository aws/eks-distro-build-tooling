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
OUTPUT_DIR="$2"
ARCHITECTURE="$3"

RELEASE_NUMBER="$(echo $VERSION | cut -d'-' -f 2)"

source $SCRIPT_ROOT/common_vars.sh

function build::go::download(){
    # Set up specific go version by using go get, additional versions apart from default can be installed by calling
    # the function again with the specific parameter.
    local version=${1%-*}
    local outputDir=${2}
    local arch=${3}

    for artifact in golang golang-bin; do
        local filename="$outputDir/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm"
        if [ ! -f $filename ]; then
            curl -sSLf --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm -o $filename --create-dirs
            curl -sSLf --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm.sha256 -o $filename.sha256

            if [[ $(sha256sum ${filename} | cut -d' ' -f1) != $(cut -d' ' -f1 "${filename}.sha256") ]] ; then 
                echo "Checksum doesn't match!"
                exit 1
            fi
        fi
    done

    for artifact in golang-docs golang-misc golang-tests golang-src; do
        local filename="$outputDir/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.noarch.rpm"
        if [ ! -f $filename ]; then
            curl -sSLf --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/noarch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.noarch.rpm -o $filename --create-dirs
            curl -sSLf --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/noarch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.noarch.rpm.sha256 -o $filename.sha256

            if [[ $(sha256sum ${filename} | cut -d' ' -f1) != $(cut -d' ' -f1 "${filename}.sha256") ]] ; then 
                echo "Checksum doesn't match!"
                exit 1
            fi
        fi
    done
}

if [[ $( echo $ARCHITECTURE | cut -d ',' -f1 ) == "linux/amd64" ]] ; then 
    build::go::download "${VERSION}" "$OUTPUT_DIR" "x86_64"
fi

if [[ $( echo $ARCHITECTURE | cut -d ',' -f2 ) == "linux/arm64" ]] ; then 
    build::go::download "${VERSION}" "$OUTPUT_DIR" "aarch64"
fi