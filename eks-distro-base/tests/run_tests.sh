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
AL_TAG=$3
TEST=$4

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

function check_base() {
    docker build \
        -t base-test:latest \
        --target check-base \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        --build-arg AL_TAG=$AL_TAG \
        --pull \
        -f ./tests/Dockerfile ./tests
    docker run base-test:latest
}

function check_base-nonroot() {
    echo "not impl"
}

function check_base-glibc() {
    docker build \
        -t base-glibc-test:latest \
        --target check-cgo \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-glibc:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        --build-arg AL_TAG=$AL_TAG \
        --pull \
        -f ./tests/Dockerfile ./tests
    
    if docker run base-glibc-test:latest | grep -v 'Printed from unsafe C code'; then
        echo "glibc issue!"
        exit 1
    fi
}

function check_base-iptables() {
    docker build \
        -t base-iptables-legacy-test:latest \
        --target check-iptables-legacy \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        --build-arg AL_TAG=$AL_TAG \
        --pull \
        -f ./tests/Dockerfile ./tests
    
    if docker run base-iptables-legacy-test:latest iptables --version | grep -v 'legacy'; then
        echo "iptables legacy issue!"
        exit 1
    fi
    if docker run base-iptables-legacy-test:latest ip6tables --version | grep -v 'legacy'; then
        echo "ip6tables legacy issue!"
        exit 1
    fi
    if ! docker run base-iptables-legacy-test:latest iptables-save; then
        echo "iptables-save legacy issue!"
        exit 1
    fi
    if ! docker run base-iptables-legacy-test:latest ip6tables-save; then
        echo "ip6tables-save legacy issue!"
        exit 1
    fi

    docker build \
        -t base-iptables-nft-test:latest \
        --target check-iptables-nft \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        --build-arg AL_TAG=$AL_TAG \
        --pull \
        -f ./tests/Dockerfile ./tests

    if docker run base-iptables-nft-test:latest iptables --version | grep -v 'nf_tables'; then
        echo "iptables nft issue!"
        exit 1
    fi
    if docker run base-iptables-nft-test:latest ip6tables --version | grep -v 'nf_tables'; then
        echo "ip6tables nft issue!"
        exit 1
    fi
    if ! docker run base-iptables-nft-test:latest ebtables --version; then
        echo "ebtables nft issue!"
        exit 1
    fi
    if ! docker run base-iptables-nft-test:latest arptables --version; then
        echo "arptables nft issue!"
        exit 1
   fi
}

function check_base-csi() {
    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-csi:$IMAGE_TAG xfs_info -V | grep -v 'xfs_info version'; then
        echo "csi xfs issue!"
        exit 1
    fi
 }

 function check_base-csi-ebs() {
    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-csi-ebs:$IMAGE_TAG mount --version | grep -v 'mount'; then
        echo "csi xfs issue!"
        exit 1
    fi
 }

 function check_base-git() {
    if [[ -z "$PRIVATE_REPO" ]]; then
        echo "Error: Please set PRIVATE_REPO to a private github repo in your github account"
        echo "example: PRIVATE_REPO=git@github.com:jaxesn/test-private.git"
        exit 1
    fi

    if [[ -z "$SSH_KEY_FOLDER" ]]; then
        echo "Error: Please set SSH_KEY_FOLDER to the local folder which contains your github private/public key"
        echo "example: SSH_KEY_FOLDER=/Users/jgw/.ssh "
        exit 1
    fi

    docker build \
        -t base-git-test:latest \
        --target check-git \
        --build-arg BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-git:$IMAGE_TAG \
        --build-arg TARGETARCH=amd64 \
        --build-arg TARGETOS=linux \
        --build-arg GOPROXY=direct \
        --build-arg AL_TAG=$AL_TAG \
        --progress plain \
        --pull \
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

 check_base-docker-client() {
    if ! docker run --pull=always -v /var/run/docker.sock:/var/run/docker.sock $IMAGE_REPO/eks-distro-minimal-base-docker-client:$IMAGE_TAG docker info; then
        echo "docker client issue!"
        exit 1
    fi
 }

 check_base-haproxy() {
    if ! docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-haproxy:$IMAGE_TAG haproxy -v; then
        echo "haproxy issue!"
        exit 1
    fi
 }

 check_base-nginx() {
    if ! docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-nginx:$IMAGE_TAG nginx -v; then
        echo "nginx issue!"
        exit 1
    fi
 }

 check_base-kind() {
    if ! docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-kind:$IMAGE_TAG ctr -v; then
        echo "kind issue!"
        exit 1
    fi
 }

 check_base-nsenter() {
    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-nsenter:$IMAGE_TAG nsenter --version | grep -v 'nsenter from util-linux'; then
        echo "nsenter issue!"
        exit 1
    fi
  }


 check_base-python3() {
    local -r version="$1"
    # Cases based on distroless's test cases
    # https://github.com/GoogleContainerTools/distroless/blob/main/experimental/python3/testdata/python3.yaml
    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "print('Hello World')" | grep -v 'Hello World'; then
        echo "python3 issue!"
        exit 1
    fi
   
    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import subprocess, sys; subprocess.check_call(sys.executable + ' --version', shell=True)" | grep -v 'Python 3'; then
        echo "python3 issue!"
        exit 1
    fi

    if ! docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import ctypes.util; ctypes.CDLL(ctypes.util.find_library('rt')).timer_create"; then
        echo "python3 issue!"
        exit 1
    fi

    if ! docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import distutils.dist"; then
        echo "python3 issue!"
        exit 1
    fi

    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "open(u'h\\xe9llo', 'w'); import sys; print(sys.getfilesystemencoding())" | grep -v 'utf-8'; then
        echo "python3 issue!"
        exit 1
    fi

    if docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "print(u'h\\xe9llo.txt')" | grep -v 'h\xe9llo'; then
        echo "python3 issue!"
        exit 1
    fi

    if docker run --pull=always -v $SCRIPT_ROOT/python3-test.py:/eks-d-python-validate.py $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 /eks-d-python-validate.py | grep -v 'FINISHED ENTIRE SCRIPT'; then
        echo "python3 issue!"
        exit 1
    fi

    if ! docker run --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"; then
        echo "python3 issue!"
        exit 1
    fi
  }

check_base-python3.7() {
    check_base-python3 3.7
}

check_base-python3.8() {
    check_base-python3 3.8
}

check_base-python3.9() {
    check_base-python3 3.9
}

$TEST
