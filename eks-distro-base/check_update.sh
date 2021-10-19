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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

IMAGE_NAME=$1
if [[ $IMAGE_NAME == *-builder ]]; then
    # ignore checking builder images
    exit 0
fi

BASE_IMAGE_TAG_FILE="${SCRIPT_ROOT}/../$(echo ${IMAGE_NAME^^} | tr '-' '_')_TAG_FILE"
BASE_IMAGE=public.ecr.aws/eks-distro-build-tooling/$IMAGE_NAME:$(cat $BASE_IMAGE_TAG_FILE)
mkdir -p check-update
cat << EOF > check-update/Dockerfile
FROM $BASE_IMAGE AS base_image

FROM public.ecr.aws/amazonlinux/amazonlinux:2 as builder

RUN rm -rf /var/lib/rpm
COPY --from=base_image /var/lib/rpm /var/lib/rpm

RUN yum check-update --security  > ./check_update_output; echo \$? > ./return_value
RUN cat ./check_update_output | awk '/^$/,0' | awk '{print \$1}' > ./update_packages

FROM scratch

COPY --from=builder ./return_value ./return_value
COPY --from=builder ./update_packages ./update_packages
EOF

buildctl build \
         --frontend dockerfile.v0 \
         --opt platform=linux/amd64 \
         --local dockerfile=./check-update \
         --local context=. \
         --progress plain \
         --output type=local,dest=/tmp/${IMAGE_NAME} \
    || {
            mkdir -p /tmp/${IMAGE_NAME}
            echo "100" > /tmp/${IMAGE_NAME}/return_value
            echo "" > /tmp/${IMAGE_NAME}/update_packages
        }

RETURN_STATUS=$(cat /tmp/${IMAGE_NAME}/return_value)
cat /tmp/${IMAGE_NAME}/update_packages > ${SCRIPT_ROOT}/update_packages-${IMAGE_NAME}

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
