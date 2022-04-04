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

function check_csi() {
    if docker run $IMAGE_REPO/eks-distro-minimal-base-csi:$IMAGE_TAG xfs_info -V | grep -v 'xfs_info version'; then
        echo "csi xfs issue!"
        exit 1
    fi
 }

 function check_git() {
    docker build \
        -t base-git-test:latest \
        --target check-git \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-git:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        --build-arg GOPROXY=direct \
        --progress plain \
        -f ./tests/Dockerfile ./tests
    
    # use git cli to clone private and public repo
    docker run -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
        -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
        -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
        base-git-test:latest git clone $PRIVATE_REPO

    docker run -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
        -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
        -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
        base-git-test:latest git clone https://github.com/aws/eks-distro.git

    # use lib git to clone private and public repo
    if docker run -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
        -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
        -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
        -e PRIVATE_REPO=$PRIVATE_REPO base-git-test:latest check-git | grep -v 'Successfully cloned!'; then
       echo "git issue!"
       exit 1
    fi

 }

 check_docker_client() {
    if ! docker run -v /var/run/docker.sock:/var/run/docker.sock $IMAGE_REPO/eks-distro-minimal-base-docker-client:$IMAGE_TAG docker info; then
        echo "docker client issue!"
        exit 1
    fi
 }

 check_haproxy() {
    if ! docker run $IMAGE_REPO/eks-distro-minimal-base-haproxy:$IMAGE_TAG haproxy -v; then
        echo "haproxy issue!"
        exit 1
    fi
 }

 check_nginx() {
    if ! docker run $IMAGE_REPO/eks-distro-minimal-base-nginx:$IMAGE_TAG nginx -v; then
        echo "nginx issue!"
        exit 1
    fi
 }

 check_kind() {
    if ! docker run $IMAGE_REPO/eks-distro-minimal-base-kind:$IMAGE_TAG ctr -v; then
        echo "kind issue!"
        exit 1
    fi
 }

check_base
check_glibc
check_iptables
check_csi
check_git
check_docker_client
check_haproxy
check_nginx
check_kind
