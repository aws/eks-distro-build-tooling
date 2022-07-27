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
PLATFORMS="$4"
TEST=$5

LOCAL_REGISTRY=localhost:5000

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

function check_base() {
    buildctl \
        build \
        --frontend dockerfile.v0 \
        --opt filename=./tests/Dockerfile \
		--opt platform=$PLATFORMS \
        --opt build-arg:BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base:$IMAGE_TAG \
        --opt build-arg:AL_TAG=$AL_TAG \
        --progress plain \
        --opt target=check-base \
        --local dockerfile=./ \
		--local context=./tests \
        --opt platform=$PLATFORMS \
		--output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/base-test:latest\",push=true

    for platform in ${PLATFORMS//,/ }; do
        docker run --platform=$platform $LOCAL_REGISTRY/base-test:latest
    done
}

function check_base-nonroot() {
    echo "not impl"
}

function check_base-glibc() {
    buildctl \
        build \
        --frontend dockerfile.v0 \
        --opt filename=./tests/Dockerfile \
		--opt platform=$PLATFORMS \
        --opt build-arg:BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-glibc:$IMAGE_TAG \
        --opt build-arg:AL_TAG=$AL_TAG \
        --progress plain \
        --opt target=check-cgo \
        --local dockerfile=./ \
		--local context=./tests \
        --opt platform=$PLATFORMS \
		--output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/base-glibc:latest\",push=true
    
    for platform in ${PLATFORMS//,/ }; do
        if docker run --platform=$platform $LOCAL_REGISTRY/base-glibc-test:latest | grep -v 'Printed from unsafe C code'; then
            echo "glibc issue!"
            exit 1
        fi
    done
}

function check_base-iptables() {
    buildctl \
        build \
        --frontend dockerfile.v0 \
        --opt filename=./tests/Dockerfile \
		--opt platform=$PLATFORMS \
        --opt build-arg:BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --opt build-arg:AL_TAG=$AL_TAG \
        --progress plain \
        --opt target=check-iptables-legacy \
        --local dockerfile=./ \
		--local context=./tests \
        --opt platform=$PLATFORMS \
		--output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/base-iptables-legacy-test:latest\",push=true
    
    buildctl \
        build \
        --frontend dockerfile.v0 \
        --opt filename=./tests/Dockerfile \
		--opt platform=$PLATFORMS \
        --opt build-arg:BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --opt build-arg:AL_TAG=$AL_TAG \
        --progress plain \
        --opt target=check-iptables-nft \
        --local dockerfile=./ \
		--local context=./tests \
        --opt platform=$PLATFORMS \
		--output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/base-iptables-nft-test:latest\",push=true
    
    for platform in ${PLATFORMS//,/ }; do
        if docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-legacy-test:latest iptables --version | grep -v 'legacy'; then
            echo "iptables legacy issue!"
            exit 1
        fi

        if docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-legacy-test:latest ip6tables --version | grep -v 'legacy'; then
            echo "ip6tables legacy issue!"
            exit 1
        fi
        if ! docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-legacy-test:latest iptables-save; then
            echo "iptables-save legacy issue!"
            exit 1
        fi
        if ! docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-legacy-test:latest ip6tables-save; then
            echo "ip6tables-save legacy issue!"
            exit 1
        fi

        # nft mode will fail when running on a host that does not match the arch, both arch have been confirmed to work on their respective
        # arch based instances
        if [[ ! "$platform" = "linux/$(go env GOHOSTARCH)" ]]; then
            continue
        fi

        if docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-nft-test:latest iptables --version | grep -v 'nf_tables'; then
            echo "iptables nft issue!"
            exit 1
        fi
        if docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-nft-test:latest ip6tables --version | grep -v 'nf_tables'; then
            echo "ip6tables nft issue!"
            exit 1
        fi
        if ! docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-nft-test:latest ebtables --version; then
            echo "ebtables nft issue!"
            exit 1
        fi
        if ! docker run --platform=$platform --pull=always $LOCAL_REGISTRY/base-iptables-nft-test:latest arptables --version; then
            echo "arptables nft issue!"
            exit 1
        fi
    done
}

function check_base-csi() {
    for platform in ${PLATFORMS//,/ }; do
        if docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-csi:$IMAGE_TAG xfs_info -V | grep -v 'xfs_info version'; then
            echo "csi xfs issue!"
            exit 1
        fi
    done
 }

 function check_base-csi-ebs() {
    for platform in ${PLATFORMS//,/ }; do
        if docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-csi-ebs:$IMAGE_TAG mount --version | grep -v 'mount'; then
            echo "csi xfs issue!"
            exit 1
        fi
    done
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

    buildctl \
        build \
        --frontend dockerfile.v0 \
        --opt filename=./tests/Dockerfile \
		--opt platform=$PLATFORMS \
        --opt build-arg:BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-git:$IMAGE_TAG \
        --opt build-arg:AL_TAG=$AL_TAG \
        --opt build-arg:GOPROXY=${GOPROXY:-direct} \
        --progress plain \
        --opt target=check-git \
        --local dockerfile=./ \
		--local context=./tests \
        --opt platform=$PLATFORMS \
		--output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/base-git-test:latest\",push=true
    
    for platform in ${PLATFORMS//,/ }; do
        # use git cli to clone private and public repo
        docker run --platform=$platform --pull=always -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
            -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
            -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
            $LOCAL_REGISTRY/base-git-test:latest git clone $PRIVATE_REPO

        docker run --platform=$platform --pull=always -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
            -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
            -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
            $LOCAL_REGISTRY/base-git-test:latest git clone https://github.com/aws/eks-distro.git

        # use lib git to clone private and public repo
        if docker run --platform=$platform --pull=always -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
            -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
            -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
            -e PRIVATE_REPO=$PRIVATE_REPO $LOCAL_REGISTRY/base-git-test:latest check-git | grep -v 'Successfully cloned!'; then
            echo "git issue!"
            exit 1
        fi
    done

 }

 check_base-docker-client() {
    for platform in ${PLATFORMS//,/ }; do
        if ! docker run --platform=$platform --pull=always -v /var/run/docker.sock:/var/run/docker.sock $IMAGE_REPO/eks-distro-minimal-base-docker-client:$IMAGE_TAG docker info; then
            echo "docker client issue!"
            exit 1
        fi
    done
 }

 check_base-haproxy() {
    for platform in ${PLATFORMS//,/ }; do
        if ! docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-haproxy:$IMAGE_TAG haproxy -v; then
            echo "haproxy issue!"
            exit 1
        fi
    done
 }

 check_base-nginx() {
    for platform in ${PLATFORMS//,/ }; do
        if ! docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-nginx:$IMAGE_TAG nginx -v; then
            echo "nginx issue!"
            exit 1
        fi
    done
 }

 check_base-kind() {
    for platform in ${PLATFORMS//,/ }; do
        if ! docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-kind:$IMAGE_TAG ctr -v; then
            echo "kind issue!"
            exit 1
        fi
    done
 }

 check_base-nsenter() {
    for platform in ${PLATFORMS//,/ }; do
        if docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-nsenter:$IMAGE_TAG nsenter --version | grep -v 'nsenter from util-linux'; then
            echo "nsenter issue!"
            exit 1
        fi
    done
  }


 check_base-python3() {
    local -r version="$1"
    # Cases based on distroless's test cases
    # https://github.com/GoogleContainerTools/distroless/blob/main/experimental/python3/testdata/python3.yaml
    for platform in ${PLATFORMS//,/ }; do
        if docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "print('Hello World')" | grep -v 'Hello World'; then
            echo "python3 issue!"
            exit 1
        fi
    
        if docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import subprocess, sys; subprocess.check_call(sys.executable + ' --version', shell=True)" | grep -v 'Python 3'; then
            echo "python3 issue!"
            exit 1
        fi

        if ! docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import ctypes.util; ctypes.CDLL(ctypes.util.find_library('rt')).timer_create"; then
            echo "python3 issue!"
            exit 1
        fi

        if ! docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import distutils.dist"; then
            echo "python3 issue!"
            exit 1
        fi

        if docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "open(u'h\\xe9llo', 'w'); import sys; print(sys.getfilesystemencoding())" | grep -v 'utf-8'; then
            echo "python3 issue!"
            exit 1
        fi

        if docker run --platform=$platform --pull=always -v $SCRIPT_ROOT/python3-test.py:/eks-d-python-validate.py $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 /eks-d-python-validate.py | grep -v 'FINISHED ENTIRE SCRIPT'; then
            echo "python3 issue!"
            exit 1
        fi

        if ! docker run --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG /usr/bin/python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"; then
            echo "python3 issue!"
            exit 1
        fi
    done
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
