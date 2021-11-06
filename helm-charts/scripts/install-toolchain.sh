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

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source $SCRIPT_ROOT/lib.sh

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$([[ $(uname -m) = "x86_64" ]] && echo 'amd64' || echo 'arm64')
TMP_DIR="${BUILD_DIR}/tmp"
mkdir -p "${TOOLS_DIR}"

HELM_VERSION=v3.7.1
KUBECTL_VERSION=v1.20.7
KIND_VERSION=v0.11.1
RELEASE_BRANCH=1-20
RELEASE=8

## Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Downloading..."
    curl -sSL "https://distro.eks.amazonaws.com/kubernetes-${RELEASE_BRANCH}/releases/${RELEASE}/artifacts/kubernetes/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o "${TOOLS_DIR}/kubectl"
    chmod +x "${TOOLS_DIR}/kubectl"
fi

## Install kubeval
if ! command -v kubeval &> /dev/null; then
    echo "kubeval could not be found. Downloading..."
    mkdir -p "${TMP_DIR}/kubeval"
    curl -sSL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/kubeval"
    mv "${TMP_DIR}/kubeval/kubeval" "${TOOLS_DIR}/kubeval"
fi

## Install helm
if ! command -v helm &> /dev/null; then
    echo "helm could not be found. Downloading..."
    mkdir -p "${TMP_DIR}/helm"
    curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/helm"
    mv "${TMP_DIR}/helm/${PLATFORM}-${ARCH}/helm" "${TOOLS_DIR}/helm"
    rm -rf "${PLATFORM}-${ARCH}"
fi

## Install kind
if ! command -v kind &> /dev/null; then
    echo "kind could not be found. Downloading..."
    curl -sSL "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-${PLATFORM}-${ARCH}" -o "${TOOLS_DIR}/kind"
    chmod +x "${TOOLS_DIR}/kind"
fi

rm -rf ${TMP_DIR}

echo "Tools installed successfully"
