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

if ! docker buildx version > /dev/null 2>&1; then
    # TODO move to builder base
    mkdir -p ~/.docker/cli-plugins
    curl -L https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx  
    chmod a+x ~/.docker/cli-plugins/docker-buildx    
fi

docker buildx version

if ! docker buildx ls | grep "sidecar-builder" > /dev/null 2>&1; then
    docker buildx create --name sidecar-builder --driver remote ${BUILDKIT_HOST:-unix:///run/buildkit/buildkitd.sock}
    docker buildx use sidecar-builder
fi

docker buildx inspect
