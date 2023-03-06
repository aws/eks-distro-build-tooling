#!/bin/bash

# Copied from https://github.com/kubernetes/release/blob/master/images/build/distroless-iptables/distroless/package-utils.sh

# Copyright 2022 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# file_to_package identifies the debian package that provided the file $1
file_to_package() {
    # `dpkg-query --search $file-pattern` outputs lines with the format: "$package: $file-path"
    # where $file-path belongs to $package
    # https://manpages.debian.org/jessie/dpkg/dpkg-query.1.en.html
    dpkg-query --search "$(realpath "${1}")" | cut -d':' -f1
}

# package_to_copyright gives the path to the copyright file for the package $1
package_to_copyright() {
    echo "/usr/share/doc/${1}/copyright"
}

# stage_file stages the filepath $1 to $2, following symlinks
# and staging copyrights
stage_file() {
    cp -a --parents "${1}" "${2}"
    # recursively follow symlinks
    if [[ -L "${1}" ]]; then
        stage_file "$(cd "$(dirname "${1}")" || exit; realpath -s "$(readlink "${1}")")" "${2}"
    fi
    # get the package so we can stage package metadata as well
    package="$(file_to_package "${1}")"
    # stage the copyright for the file
    cp -a --parents "$(package_to_copyright "${package}")" "${2}"
    # stage the package status mimicking bazel
    # https://github.com/bazelbuild/rules_docker/commit/f5432b813e0a11491cf2bf83ff1a923706b36420
    # instead of parsing the control file, we can just get the actual package status with dpkg
    dpkg -s "${package}" > "${2}/var/lib/dpkg/status.d/${package}"
}
