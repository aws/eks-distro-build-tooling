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
set -x
set -o errexit
set -o nounset
set -o pipefail

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

declare -A cases["coredns/coredns"]='github.com/coredns/coredns' 
    cases['containernetworking/plugins']='github.com/containernetworking/plugins'
    cases['etcd-io/etcd']='go.etcd.io/etcd'
    cases['kubernetes/release']='k8s.io/release/images/build/go-runner'
    cases['kubernetes-csi/external-attacher']='github.com/kubernetes-csi/external-attacher'
    cases['kubernetes-csi/external-provisioner']='github.com/kubernetes-csi/external-provisioner'
    cases['kubernetes-csi/external-resizer']='github.com/kubernetes-csi/external-resizer'
    cases['kubernetes-csi/external-snapshotter']='github.com/kubernetes-csi/external-snapshotter/v3'
    cases['kubernetes-csi/livenessprobe']='github.com/kubernetes-csi/livenessprobe'
    cases['kubernetes-csi/node-driver-registrar']='github.com/kubernetes-csi/node-driver-registrar'
    cases['kubernetes-sigs/aws-iam-authenticator']='sigs.k8s.io/aws-iam-authenticator'
    cases['kubernetes-sigs/cri-tools']='github.com/kubernetes-sigs/cri-tools'
    cases['kubernetes-sigs/metrics-server']='sigs.k8s.io/metrics-server'
    cases['kubernetes/kubernetes-1-19']='k8s.io/'

for i in "${!cases[@]}"
do
  rm -f "$SRC_ROOT/tests/cases/$i/_output/ATTRIBUTION.txt"
  (cd "$SRC_ROOT/tests/cases/$i" &&  node $SRC_ROOT/generate-attribution-file.js ${cases[$i]} ./ go1.15.6 ./_output)
  (cd "$SRC_ROOT/tests/cases/$i" && diff ./_output/attribution/ATTRIBUTION.txt ATTRIBUTION.txt)
done
