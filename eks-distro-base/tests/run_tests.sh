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


set -e
set -o pipefail
set -x

IMAGE_REPO=$1
IMAGE_TAG=$2

function check_base() {
    docker build \
        -t base-test:latest \
        --target check-base \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        -f ./tests/Dockerfile ./tests
    docker run base-test:latest
}


function check_glibc() {
    docker build \
        -t base-glibc-test:latest \
        --target check-cgo \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-glibc:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        -f ./tests/Dockerfile ./tests
    
    if docker run base-glibc-test:latest | grep -v 'Printed from unsafe C code'; then
        echo "glibc issue!"
        exit 1
    fi
}

function check_iptables() {
    docker build \
        -t base-iptables-legacy-test:latest \
        --target check-iptables-legacy \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        -f ./tests/Dockerfile ./tests
    
    if docker run base-iptables-legacy-test:latest iptables --version | grep -v 'legacy'; then
        echo "iptables legacy issue!"
        exit 1
    fi
    if docker run base-iptables-legacy-test:latest ip6tables --version | grep -v 'legacy'; then
        echo "ip6tables legacy issue!"
        exit 1
    fi

    docker build \
        -t base-iptables-nft-test:latest \
        --target check-iptables-nft \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        -f ./tests/Dockerfile ./tests

    if docker run base-iptables-nft-test:latest iptables --version | grep -v 'nf_tables'; then
        echo "iptables nft issue!"
        exit 1
    fi
    if docker run base-iptables-nft-test:latest ip6tables --version | grep -v 'nf_tables'; then
        echo "ip6tables nft issue!"
        exit 1
    fi
}

check_base
check_glibc
check_iptables
