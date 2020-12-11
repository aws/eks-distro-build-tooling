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

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-west-2"
BASE_IMAGE=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/eks-distro/base:$(cat eks-distro-base/TAG_FILE)
mkdir eks-distro-base/check-update
cat << EOF >> eks-distro-base/check-update/Dockerfile
FROM $BASE_IMAGE AS base_image

RUN (yum check-update --security) && true
RUN echo $? > ./return_value

FROM scratch

COPY --from=base_image ./return_value ./return_value
EOF

sleep 10
buildctl build \
         --frontend dockerfile.v0 \
         --opt platform=linux/amd64 \
         --local dockerfile=./eks-distro-base/check-update \
         --local context=. \
         --output type=local,dest=/tmp/status

RETURN_STATUS=$(cat /tmp/status/return_value)

if [ $RETURN_STATUS -eq 100 ]; then
    bash ./eks-distro-base/update_base_image.sh
elif [ $RETURN_STATUS -eq 1 ]; then
    exit 1
fi
