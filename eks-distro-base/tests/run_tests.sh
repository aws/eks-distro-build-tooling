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
LOCAL_REGISTRY=$6

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ "$AL_TAG" = "2023" ]; then
    AL_TAG="23"
fi

function retry() {
  local n=1
  local max=120
  local delay=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        sleep $delay;
      fi
    }
  done
}

function build::docker::retry_pull() {
  retry docker pull "$@"
}

function check_base() {
    $SCRIPT_ROOT/../../scripts/buildkit.sh  \
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
        --export-cache type=inline \
        --import-cache type=registry,ref=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:base-latest \
        --output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:base-latest\",push=true

    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:base-latest
        if ! docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:base-latest; then
            echo "base issue!"
            exit 1
        fi
    done
}

function check_base-nonroot() {
    echo "not impl"
}

function check_base-glibc() {
    $SCRIPT_ROOT/../../scripts/buildkit.sh  \
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
        --export-cache type=inline \
        --import-cache type=registry,ref=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:glibc-latest \
        --output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:glibc-latest\",push=true

    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:glibc-latest
        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:glibc-latest | grep -v 'Printed from unsafe C code'; then
            echo "glibc issue!"
            exit 1
        fi
    done
}

function cleanup-iptable-rules() {
    local mode
    local ip
    for mode in legacy nft; do
        # ensure they do not already exist
        for ip in iptables ip6tables; do
            docker run --privileged --rm --net host --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-$mode-latest $ip -t mangle -X KUBE-IPTABLES-HINT &> /dev/null || true            
        done
    done
}

function check_base-iptables() {
    $SCRIPT_ROOT/../../scripts/buildkit.sh  \
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
        --export-cache type=inline \
        --import-cache type=registry,ref=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest \
        --output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest\",push=true

    $SCRIPT_ROOT/../../scripts/buildkit.sh  \
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
        --export-cache type=inline \
        --import-cache type=registry,ref=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest \
        --output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest\",push=true

    $SCRIPT_ROOT/../../scripts/buildkit.sh  \
        build \
        --frontend dockerfile.v0 \
        --opt filename=./tests/Dockerfile \
		--opt platform=$PLATFORMS \
        --opt build-arg:BASE_IMAGE=$IMAGE_REPO/eks-distro-minimal-base-iptables:$IMAGE_TAG \
        --opt build-arg:AL_TAG=$AL_TAG \
        --progress plain \
        --opt target=check-iptables-wrapper \
        --local dockerfile=./ \
		--local context=$SCRIPT_ROOT/../ \
        --export-cache type=inline \
        --import-cache type=registry,ref=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest \
        --output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest\",push=true

    local platform
    local mode
    local ip
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest

        # ensure defatult is set to legacy which was set in dockerfile
        if [[ "$(docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest update-alternatives --list | grep 'iptables' | xargs)" != "iptables manual /usr/sbin/iptables-legacy" ]]; then
            echo "iptables legacy alternative issue!"
            exit 1
        fi
        
        if [[ "$(docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest update-alternatives --list | grep 'ip6tables' | xargs)" != "ip6tables manual /usr/sbin/ip6tables-legacy" ]]; then
            echo "ip6tables legacy alternative issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest iptables --version | grep -v 'legacy'; then
            echo "iptables legacy issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest ip6tables --version | grep -v 'legacy'; then
            echo "ip6tables legacy issue!"
            exit 1
        fi
        
        if ! docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest iptables-save; then
            echo "iptables-save legacy issue!"
            exit 1
        fi
        if ! docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-legacy-latest ip6tables-save; then
            echo "ip6tables-save legacy issue!"
            exit 1
        fi

        # nft mode will fail when running on a host that does not match the arch, both arch have been confirmed to work on their respective
        # arch based instances
        if [[ ! "$platform" = "linux/$(go env GOHOSTARCH)" ]]; then
            continue
        fi
        
        build::docker::retry_pull --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest

        # ensure defatult is set to nft which was set in dockerfile
        if [[ "$(docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest update-alternatives --list | grep 'iptables' | xargs)" != "iptables manual /usr/sbin/iptables-nft" ]]; then
            echo "iptables nft alternative issue!"
            exit 1
        fi
        
        if [[ "$(docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest update-alternatives --list | grep 'ip6tables' | xargs)" != "ip6tables manual /usr/sbin/ip6tables-nft" ]]; then
            echo "ip6tables nft alternative issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest iptables --version | grep -v 'nf_tables'; then
            echo "iptables nft issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest ip6tables --version | grep -v 'nf_tables'; then
            echo "ip6tables nft issue!"
            exit 1
        fi

        # these are included to match upstream, but default to nft and are not explictly set anywhere accross eks-d/a
        if ! docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest ebtables --version; then
            echo "ebtables nft issue!"
            exit 1
        fi

        if ! docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-nft-latest arptables --version; then
            echo "arptables nft issue!"
            exit 1
        fi


        build::docker::retry_pull --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest

        # ensure defatult is set to wrapper which was set in dockerfile
        if [[ "$(docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest update-alternatives --list | grep '^iptables' | xargs)" != "iptables manual /usr/sbin/iptables-wrapper" ]]; then
            echo "iptables wrapper alternative issue!"
            exit 1
        fi
        
        if [[ "$(docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest update-alternatives --list | grep 'ip6tables' | xargs)" != "ip6tables manual /usr/sbin/iptables-wrapper" ]]; then
            echo "ip6tables wrapper alternative issue!"
            exit 1
        fi
        
        # iptables-wrapper defaults to nft mode when none of the kubelet hint rules are set
        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest iptables --version | grep -v 'nf_tables'; then
            echo "iptables wrapper issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest ip6tables --version | grep -v 'nf_tables'; then
            echo "ip6tables wrapper issue!"
            exit 1
        fi
        
        # create KUBE-IPTABLES-HINT and test that wrapper sets the correct mode        
        for mode in nft legacy; do
            local expected="$mode"
            if [[ "$mode" == "nft" ]]; then
                expected="nf_tables"
            fi

            # no matter which version of a given iptables mode is used to add the hint, it should trigger the wrapper to use that mode for both
            # depending on how the hint rule is set, the resulting mode should be set
            for ip in iptables ip6tables; do
                cleanup-iptable-rules

                docker run --privileged --rm --net host --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-$mode-latest $ip -t mangle -N KUBE-IPTABLES-HINT

                if docker run --privileged --net host --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest iptables --version | grep -v "$expected"; then
                    echo "iptables wrapper issue!"
                    exit 1
                fi
                
                if docker run --privileged --net host --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest ip6tables --version | grep -v "$expected"; then
                    echo "iptables wrapper issue!"
                    exit 1
                fi
            done
        done
        
        cleanup-iptable-rules

        # run upstream test binaries which tests a number of similiar cases as above
        if ! docker run --privileged --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest /tests -test.v -test.run "^TestIPTablesWrapperLegacy$"; then
            echo "iptables wrapper legacy issue!"
            exit 1
        fi
        
        if ! docker run --privileged --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest /tests -test.v -test.run "^TestIPTablesWrapperNFT$"; then
            echo "iptables wrapper nft issue!"
            exit 1
        fi

        if ! docker run --privileged --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest /tests -test.v -test.run "^TestIP6TablesWrapperLegacy$"; then
            echo "iptables wrapper ipv6 legacy issue!"
            exit 1
        fi

        if ! docker run --privileged --rm --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:iptables-wrapper-latest /tests -test.v -test.run "^TestIP6TablesWrapperNFT$"; then
            echo "ip6tables wrapper ipv6 nft issue!"
            exit 1
        fi
    done
}

function check_base-csi() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-csi:$IMAGE_TAG
        if docker run --rm --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-csi:$IMAGE_TAG xfs_info -V | grep -v 'xfs_info version'; then
            echo "csi xfs issue!"
            exit 1
        fi
    done
 }

 function check_base-csi-ebs() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-csi-ebs:$IMAGE_TAG
        if docker run --rm --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-csi-ebs:$IMAGE_TAG mount --version | grep -v 'mount'; then
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

    local netrc=""
    if [ -f $HOME/.netrc ]; then
        netrc="--secret id=netrc,src=$HOME/.netrc"
    fi

    $SCRIPT_ROOT/../../scripts/buildkit.sh  \
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
		--local context=./tests $netrc \
        --export-cache type=inline \
        --import-cache type=registry,ref=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:git-latest \
        --output type=image,oci-mediatypes=true,\"name=$LOCAL_REGISTRY/eks-distro-minimal-images-base-test:git-latest\",push=true

    for platform in ${PLATFORMS//,/ }; do
        # use git cli to clone private and public repo
        build::docker::retry_pull --platform=$platform $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:git-latest
        docker run --rm --platform=$platform -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
            -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
            -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
            $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:git-latest git clone $PRIVATE_REPO

        docker run --rm --platform=$platform -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
            -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
            -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
            $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:git-latest git clone https://github.com/aws/eks-distro.git

        # use lib git to clone private and public repo
        if docker run --rm --platform=$platform -v $SSH_KEY_FOLDER/id_rsa:/root/.ssh/id_rsa \
            -v $SSH_KEY_FOLDER/id_rsa.pub:/root/.ssh/id_rsa.pub \
            -v $SSH_KEY_FOLDER/known_hosts:/root/.ssh/known_hosts \
            -e PRIVATE_REPO=$PRIVATE_REPO $LOCAL_REGISTRY/eks-distro-minimal-images-base-test:git-latest check-git | grep -v 'Successfully cloned!'; then
            echo "git issue!"
            exit 1
        fi
    done

 }

 check_base-docker-client() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-docker-client:$IMAGE_TAG

        if ! docker run --rm --platform=$platform -v /var/run/docker.sock:/var/run/docker.sock $IMAGE_REPO/eks-distro-minimal-base-docker-client:$IMAGE_TAG docker info; then
            echo "docker client issue!"
            exit 1
        fi
    done
 }

 check_base-haproxy() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-haproxy:$IMAGE_TAG

        if ! docker run --rm --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-haproxy:$IMAGE_TAG haproxy -v; then
            echo "haproxy issue!"
            exit 1
        fi
    done
 }

 check_base-nginx() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-nginx:$IMAGE_TAG

        if ! docker run --rm --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-nginx:$IMAGE_TAG nginx -v; then
            echo "nginx issue!"
            exit 1
        fi
    done
 }

 check_base-kind() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-kind:$IMAGE_TAG

        if ! docker run --rm --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-kind:$IMAGE_TAG ctr -v; then
            echo "kind issue!"
            exit 1
        fi
    done
 }

 check_base-nsenter() {
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/eks-distro-minimal-base-nsenter:$IMAGE_TAG

        if docker run --rm --platform=$platform  $IMAGE_REPO/eks-distro-minimal-base-nsenter:$IMAGE_TAG nsenter --version | grep -v 'nsenter from util-linux'; then
            echo "nsenter issue!"
            exit 1
        fi
    done
  }


 check_base-python3() {
    local -r version="$1"
    local -r image_component="${2:-eks-distro-minimal-base-python}"
    # Cases based on distroless's test cases
    # https://github.com/GoogleContainerTools/distroless/blob/main/experimental/python3/testdata/python3.yaml
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG

        if docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 -c "print('Hello World')" | grep -v 'Hello World'; then
            echo "python3 issue!"
            exit 1
        fi
    
        if docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 -c "import subprocess, sys; subprocess.check_call(sys.executable + ' --version', shell=True)" | grep -v 'Python 3'; then
            echo "python3 issue!"
            exit 1
        fi

        if ! docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 -c "import ctypes.util; ctypes.CDLL(ctypes.util.find_library('rt')).timer_create"; then
            echo "python3 issue!"
            exit 1
        fi

        if ! docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 -c "import distutils.dist"; then
            echo "python3 issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 -c "open(u'h\\xe9llo', 'w'); import sys; print(sys.getfilesystemencoding())" | grep -v 'utf-8'; then
            echo "python3 issue!"
            exit 1
        fi

        if docker run --rm --platform=$platform -v $SCRIPT_ROOT/python3-test.py:/eks-d-python-validate.py $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 /eks-d-python-validate.py | grep -v 'FINISHED ENTIRE SCRIPT'; then
            echo "python3 issue!"
            exit 1
        fi

        if ! docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG /usr/bin/python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"; then
            echo "python3 issue!"
            exit 1
        fi
    done
  }

check_base-python-3.7() {
    check_base-python3 3.7
    if docker run --rm --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG pip3 --version >/dev/null 2>&1; then
        echo "pip should not exist!"
        exit 1
    fi
}

check_base-python-3.9() {
    check_base-python3 3.9
    if docker run --rm --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-python:$IMAGE_TAG pip3 --version >/dev/null 2>&1; then
        echo "pip should not exist!"
        exit 1
    fi
}

check_base-python-compiler() {
    local -r version="$1"
    local -r variant="$2"

    check_base-compiler-$2 python
    check_base-python3 "$1" python

    for platform in ${PLATFORMS//,/ }; do
        if ! docker run --rm --platform=$platform --pull=always $IMAGE_REPO/python:$IMAGE_TAG pip3 --version; then
            echo "python issue!"
            exit 1
        fi
    done
}

check_base-python-compiler-3.7-base() {
    check_base-python-compiler 3.7 base
}

check_base-python-compiler-3.7-yum() {
    check_base-python-compiler 3.7 yum
}

check_base-python-compiler-3.7-gcc() {
    check_base-python-compiler 3.7 gcc
}

check_base-python-compiler-3.9-base() {
    check_base-python-compiler 3.9 base
}

check_base-python-compiler-3.9-yum() {
    check_base-python-compiler 3.9 yum
}

check_base-python-compiler-3.9-gcc() {
    check_base-python-compiler 3.9 gcc
}

check_base-nodejs() {
    local -r version="$1"
    local -r image_component="${2:-eks-distro-minimal-base-nodejs}"
    for platform in ${PLATFORMS//,/ }; do
        if docker run --rm --platform=$platform --pull=always $IMAGE_REPO/$image_component:$IMAGE_TAG node --version | grep -v $version; then
            echo "nodejs issue!"
            exit 1
        fi

        if ! docker run --rm --platform=$platform --pull=always $IMAGE_REPO/$image_component:$IMAGE_TAG env node; then
            echo "nodejs issue!"
            exit 1
        fi

    done
}

check_base-nodejs-16() {
    check_base-nodejs 16

    if docker run --rm --platform=$platform --pull=always $IMAGE_REPO/eks-distro-minimal-base-nodejs:$IMAGE_TAG npm --version > /dev/null 2>&1; then
        echo "npm should not exist!"
        exit 1
    fi
}

check_base-nodejs-compiler() {
    local -r version="$1"
    local -r variant="$2"

    check_base-compiler-$2 nodejs
    check_base-nodejs "$1" nodejs

    for platform in ${PLATFORMS//,/ }; do
        if docker run --rm --platform=$platform --pull=always $IMAGE_REPO/nodejs:$IMAGE_TAG npm --version | grep -v '8'; then
            echo "npm issue!"
            exit 1
        fi
    done
}


check_base-nodejs-compiler-16-base() {
    check_base-nodejs-compiler 16 base
}

check_base-nodejs-compiler-16-yum() {
    check_base-nodejs-compiler 16 yum
}

check_base-nodejs-compiler-16-gcc() {
    check_base-nodejs-compiler 16 gcc
}


check_base-compiler-base() {
    local -r image_component="${1:-compiler-base}"
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG

        if ! docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG curl --version; then
            echo "compiler-base issue!"
            exit 1
        fi
    done
}

check_base-compiler-yum() {
    local -r image_component="${1:-compiler-base}"
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG

        if ! docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG yum --version; then
            echo "compiler-base issue!"
            exit 1
        fi
    done
}

check_base-compiler-gcc() {
    local -r image_component="${1:-compiler-base}"
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG

        if ! docker run --rm --platform=$platform $IMAGE_REPO/$image_component:$IMAGE_TAG gcc --version; then
            echo "compiler-base issue!"
            exit 1
        fi
    done
}

check_base-golang-compiler() {
    local -r version="$1"
    local -r variant="$2"

    check_base-compiler-$2 golang
    
    for platform in ${PLATFORMS//,/ }; do
        build::docker::retry_pull --platform=$platform $IMAGE_REPO/golang:$IMAGE_TAG

        if docker run --rm --platform=$platform $IMAGE_REPO/golang:$IMAGE_TAG go version | grep -v $version; then
            echo "golang issue!"
            exit 1
        fi
    done
}

check_base-golang-compiler-1.17-base() {
    check_base-golang-compiler 1.17 base
}

check_base-golang-compiler-1.17-yum() {
    check_base-golang-compiler 1.17 yum
}

check_base-golang-compiler-1.17-gcc() {
    check_base-golang-compiler 1.17 gcc
}

check_base-golang-compiler-1.18-base() {
    check_base-golang-compiler 1.18 base
}

check_base-golang-compiler-1.18-yum() {
    check_base-golang-compiler 1.18 yum
}

check_base-golang-compiler-1.18-gcc() {
    check_base-golang-compiler 1.18 gcc
}

check_base-golang-compiler-1.19-base() {
    check_base-golang-compiler 1.19 base
}

check_base-golang-compiler-1.19-yum() {
    check_base-golang-compiler 1.19 yum
}

check_base-golang-compiler-1.19-gcc() {
    check_base-golang-compiler 1.19 gcc
}

check_base-golang-compiler-1.20-base() {
    check_base-golang-compiler 1.20 base
}

check_base-golang-compiler-1.20-yum() {
    check_base-golang-compiler 1.20 yum
}

check_base-golang-compiler-1.20-gcc() {
    check_base-golang-compiler 1.20 gcc
}


$TEST
