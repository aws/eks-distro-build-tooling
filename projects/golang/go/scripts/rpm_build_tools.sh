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

function common::deps::install() {
    yum install -y yum-utils
    yum install -y rpmdevtools
}

function common::download::go-1-16() {
    yumdownloader --destdir=/tmp --source golang-1.16.15-1.amzn2.0.1

    mkdir -p /root/rpmbuild/{RPMS,SOURCES,SRPMS,SPECS}
    mkdir -p /root/rpmbuild/RPMS/noarch

    mkdir /tmp/go-1-16
    (cd /tmp/go-1-16 && rpm2cpio /tmp/golang-1.16.15-1.amzn2.0.1.src.rpm | cpio -idmv)
    cp -rf /tmp/go-1-16/* /root/rpmbuild/SOURCES
    mv /root/rpmbuild/SOURCES/{fedora.go,golang.spec} /root/rpmbuild/SPECS
}

function common::deps::install-for-go-1-16() {
    (cd /root/rpmbuild/SPECS && yum-builddep golang.spec)
}

function common::build::go-1-16() {
    (cd /root/rpmbuild/SPECS && rpmbuild -bb golang.spec)
}

common::deps::install
common::download::go-1-16
common::deps::install-for-go-1-16
common::build::go-1-16