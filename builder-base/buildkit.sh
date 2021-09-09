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

# Script to perform buildkit builds in daemonless mode

set -e
set -o pipefail
set -x

tmp=$(mktemp -d /tmp/buildctl-daemonless.XXXXXX)
trap "kill \$(cat $tmp/pid); rm -rf $tmp" EXIT

start::buildkitd() {
    buildkitd --addr=unix:///run/buildkit/buildkitd.sock --oci-worker-platform=linux/amd64 --oci-worker-platform=linux/arm64 >$tmp/log 2>&1 &
    pid=$!
    echo $pid >$tmp/pid
}

wait::for::buildkitd() {
    try=0
    max_retries=10
    until buildctl --addr=unix:///run/buildkit/buildkitd.sock debug workers >/dev/null 2>&1; do
        if [ $try -gt $max_retries ]; then
            echo >&2 "could not connect to Buildkit socket after $max_retries trials"
            echo >&2 "========== log =========="
            cat >&2 $tmp/log
            exit 1
        fi
        sleep $(awk "BEGIN{print (100 + $try * 20) * 0.001}")
        try=$(expr $try + 1)
    done
}

start::buildkitd
wait::for::buildkitd

buildctl --addr=unix:///run/buildkit/buildkitd.sock "$@"