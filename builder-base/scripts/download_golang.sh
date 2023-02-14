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

RELEASE_NUMBER="$(echo $VERSION | cut -d'-' -f 2)"

source $SCRIPT_ROOT/common_vars.sh

function build::go::download(){
    # Set up specific go version by using go get, additional versions apart from default can be installed by calling
    # the function again with the specific parameter.
    local version=${1%-*}
    local outputDir=${2}
    local arch=${3}

    mkdir $outputDir/tmp

    for artifact in golang golang-bin; do
        local filename="$outputDir/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm"
        if [ ! -f $filename ]; then
            curl -sSL --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm -o $filename
        fi

        local shaCheckFilename="$outputDir/tmp/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm"
        curl -sSL --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm -o $shaCheckFilename
        curl -sSL --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/$arch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm.sha256 -o $shaCheckFilename.sha256

        if [[ $(sha256sum ${shaCheckFilename} | cut -d' ' -f1) != $(cut -d' ' -f1 "${shaCheckFilename}.sha256") ]] ; then 
            echo "Checksum doesn't match!"
            exit 1
        fi
    done

    for artifact in golang-docs golang-misc golang-tests golang-src; do
        local filename="$outputDir/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.noarch.rpm"
        if [ ! -f $filename ]; then
            curl -sSL --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/noarch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.noarch.rpm -o $filename
        fi

        local shaCheckFilename="$outputDir/tmp/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.noarchrpm"
        curl -sSL --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/noarch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.$arch.rpm -o $shaCheckFilename
        curl -sSL --retry 5 https://distro.eks.amazonaws.com/golang-go$version/releases/$RELEASE_NUMBER/$arch/RPMS/noarch/$artifact-$version-$RELEASE_NUMBER.amzn2.eks.noarch.rpm.sha256 -o $shaCheckFilename.sha256

        if [[ $(sha256sum ${shaCheckFilename} | cut -d' ' -f1) != $(cut -d' ' -f1 "${shaCheckFilename}.sha256") ]] ; then 
            echo "Checksum doesn't match!"
            exit 1
        fi
    done

    rm -rf $outputDir/tmp
}

build::go::download "${VERSION}" "$OUTPUT_DIR" "x86_64"
build::go::download "${VERSION}" "$OUTPUT_DIR" "aarch64"
