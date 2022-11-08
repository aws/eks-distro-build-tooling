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

if [ "$2" == "" ]; then
    echo "Please specify a Go Git Tag to use for the given Go Minor Version"
    exit 1
fi
GOLANG_GIT_TAG=$2


BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/golang/go/"
VERSION_DIRECTORY="${PROJECT_DIRECTORY}${GOLANG_MINOR_VERSION}"

mkdir "$VERSION_DIRECTORY"

mkdir ${VERSION_DIRECTORY}/patches
mkdir ${VERSION_DIRECTORY}/rpmbuild
mkdir ${VERSION_DIRECTORY}/rpmbuild/SOURCES
mkdir ${VERSION_DIRECTORY}/rpmbuild/SPECS

touch ${VERSION_DIRECTORY}/GIT_TAG
echo "$GOLANG_GIT_TAG" >> ${VERSION_DIRECTORY}/GIT_TAG

touch ${VERSION_DIRECTORY}/RELEASE
echo "0" >> ${VERSION_DIRECTORY}/RELEASE

( ${BASE_DIRECTORY}/projects/golang/go/development/scripts/setup_golang_version_readme.sh $GOLANG_MINOR_VERSION $GOLANG_GIT_TAG)