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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

IMAGE_TAG=$1

BASE_IMAGE=public.ecr.aws/eks-distro-build-tooling/eks-distro-base:$(cat ${SCRIPT_ROOT}/../EKS_DISTRO_BASE_TAG_FILE)
mkdir check-update
cat << 'EOF' >> check-update/Dockerfile
FROM $BASE_IMAGE AS base_image

RUN yum check-update > ./check_update_output; echo $? > ./return_value
RUN cat ./check_update_output | awk 'NR>2 {print $1}' > ./update_packages

FROM scratch

COPY --from=base_image ./return_value ./return_value
COPY --from=base_image ./update_packages ./update_packages
EOF
sed -i "s,\$BASE_IMAGE,$BASE_IMAGE," check-update/Dockerfile

buildctl build \
         --frontend dockerfile.v0 \
         --opt platform=linux/amd64 \
         --local dockerfile=./check-update \
         --local context=. \
         --output type=local,dest=/tmp/${IMAGE_TAG}

RETURN_STATUS=$(cat /tmp/${IMAGE_TAG}/return_value)
cat /tmp/${IMAGE_TAG}/update_packages > ${SCRIPT_ROOT}/update_packages

if [ "$JOB_TYPE" != "periodic" ]; then
    exit 0
fi

if [ $RETURN_STATUS -eq 100 ]; then
    echo "Updates required"
elif [ $RETURN_STATUS -eq 0 ]; then
    echo "No updates required"
elif [ $RETURN_STATUS -eq 1 ]; then
    echo "Error"
fi
