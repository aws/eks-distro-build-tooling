#!/bin/sh

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

# USAGE: clean-distroless.sh

# Modified version of https://github.com/kubernetes/release/blob/master/images/build/distroless-iptables/distroless/clean-distroless.sh

REMOVE="/usr/share/base-files
/usr/share/man
/usr/lib/*-linux-gnu/gconv/
/usr/bin/c_rehash
/usr/bin/openssl
/bin/mv
/bin/chmod
/bin/grep
/bin/ln
/bin/sleep
/usr/bin/wc
/iptables-wrapper-installer.sh
/bin/sh
/bin/dash
/clean-distroless.sh
/bin/rm"

IFS="
"

for item in ${REMOVE}; do
    rm -rf "${item}"
done
