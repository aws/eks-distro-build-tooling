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

BASE_IMAGE=319341287998.dkr.ecr.us-west-2.amazonaws.com/eks-distro/base:4834bc2a2e2eea3b14dc3b0cbbf5ac1f7cfba156
mkdir eks-distro-base/check-update
cat << EOF >> eks-distro-base/check-update/Dockerfile
FROM $BASE_IMAGE AS base_image

RUN yum check-update --security
RUN echo $? > ./return_value

FROM scratch

COPY --from=base_image ./return_value ./return_value
EOF
sleep 10
buildctl build \
         --frontend dockerfile.v0 \
         --opt platform=linux/amd64 \
         --local dockerfile=./eks-distro/check-update \
         --local context=. \
         --output type=local,dest=/tmp/return_status.tar

tar -xvf /tmp/return_status.tar
ls
ls return_status
cat return_status/return_value
RETURN_STATUS=$(cat return_status)
if [ $RETURN_STATUS -eq 0 ]; then
    bash ./eks-distro-base/install.sh
    export TZ=America/Los_Angeles
    export DATE_EPOCH=$(date "+%F-%s")
    make release -C eks-distro-base DEVELOPMENT=false IMAGE_TAG=${DATE_EPOCH}
    bash ./eks-distro-base/create_pr.sh eks-distro-build-tooling '.*' ${DATE_EPOCH} TAG_FILE
    bash ./eks-distro-base/create_pr.sh eks-distro 'BASE_TAG?=.*' 'BASE_TAG?='"${DATE_EPOCH}" Makefile
    bash ./eks-distro-base/create_pr.sh eks-distro-prow-jobs '\(eks-distro/base\):.*' '\1:'"${DATE_EPOCH}" eks-distro-base-periodics.yaml
fi
