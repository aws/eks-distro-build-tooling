#!/usr/bin/env bash
# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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

# Script to perform docker builds in daemonless mode

set -e
set -o pipefail
set -x

start::dockerd() {
    dockerd --host=unix:///var/run/docker.sock --host=tcp://127.0.0.1:2375 &>/var/log/docker.log &
}

wait::for::dockerd() {
    try=0
    max_retries=10
    until docker info >/dev/null 2>&1; do
        if [ $try -gt $max_retries ]; then
            echo >&2 "could not connect to Docker socket after $max_retries trials"
            echo >&2 "========== log =========="
            cat /var/log/docker.log
            exit 1
        fi
        sleep $(awk "BEGIN{print (100 + $try * 20) * 0.001}")
        try=$(expr $try + 1)
    done
}

start::dockerd
wait::for::dockerd
