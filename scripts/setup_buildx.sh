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

BUILDER_NAME="eks-d-builders"

function install_kubectl() {
    local -r kubectl_version=v1.23.12
    local -r eks_d_release_branch=1-23
    local -r eks_d_release_number=6
    curl -sSL "https://distro.eks.amazonaws.com/kubernetes-${eks_d_release_branch}/releases/${eks_d_release_number}/artifacts/kubernetes/${kubectl_version}/bin/linux/amd64/kubectl" -o /bin/kubectl
    chmod +x /bin/kubectl
}

function setup_kubeconfig_in_pod() {
    install_kubectl
    
    for f in "token" "ca.crt"; do
        if [ ! -f "/var/run/secrets/kubernetes.io/serviceaccount/${f}" ]; then
            echo "/var/run/secrets/kubernetes.io/serviceaccount/${f} missing!"
            exit 1
        fi
    done

    kubectl config set-cluster cfc --server=https://kubernetes.default --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    kubectl config set-context cfc --cluster=cfc
    kubectl config set-credentials user --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    kubectl config set-context cfc --user=user
    kubectl config use-context cfc
}

docker buildx version

if ! docker buildx ls | grep $BUILDER_NAME > /dev/null 2>&1; then
    # in postsubmit we create builders for both amd and arm since buildx doesnt support
    # different types of drivers within the same group
    if [ ${CREATE_BUILDER_PODS:-false} = "true" ]; then
        if ! kubectl config current-context > /dev/null 2>&1; then
            if [ ! -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
                echo "No kubeconfig or service account!"
                exit 1
            fi
            setup_kubeconfig_in_pod
        fi

        kubectl get pods -n buildkit-orchestration
        kubectl get deployments -n buildkit-orchestration

        # created buildkit are destroyed in a trap at the end of the prow job
        # in the case where jobs are evicted or otherwise crash where the trap does
        # not fire, they can be left around. cleanup any instances older than 1 day
        # https://stackoverflow.com/a/53989428 - match the 5 column which is the age against a nuber folloed by "d"
        kubectl delete deployments -n buildkit-orchestration $(kubectl get deployments -n buildkit-orchestration | awk 'match($5,/[0-9]+d/) {print $1}')

        docker buildx create \
            --bootstrap \
            --name=$BUILDER_NAME \
            --driver=kubernetes \
            --platform=linux/amd64 \
            --node=builder-amd64-${PROW_JOB_ID:-1} \
            --driver-opt=namespace=buildkit-orchestration,nodeselector="arch=AMD64",rootless=true,image=${BUILDKITD_IMAGE:-moby/buildkit:v0.10.5-rootless}

        docker buildx create \
            --bootstrap \
            --append \
            --name=$BUILDER_NAME \
            --driver=kubernetes \
            --platform=linux/arm64 \
            --node=builder-arm64-${PROW_JOB_ID:-1} \
            --driver-opt=namespace=buildkit-orchestration,nodeselector="arch=ARM64",rootless=true,image=${BUILDKITD_IMAGE:-moby/buildkit:v0.10.5-rootless}

        kubectl get pods -n buildkit-orchestration
        kubectl get deployments -n buildkit-orchestration

    else
        if [ -n "${BUILDKIT_HOST_AMD64}" ] && [ -n "${BUILDKIT_HOST_ARM64}" ]; then
            docker buildx create --name $BUILDER_NAME --platform=linux/amd64 --driver remote ${BUILDKIT_HOST_AMD64}
            docker buildx create --append --name $BUILDER_NAME --platform=linux/arm64 --driver remote ${BUILDKIT_HOST_ARM64}
        else
            # in presubmit we just attach to the sidecar container
            docker buildx create --name $BUILDER_NAME --driver remote ${BUILDKIT_HOST:-unix:///run/buildkit/buildkitd.sock}
        fi
    fi
fi

docker buildx inspect $BUILDER_NAME
docker buildx use $BUILDER_NAME
