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

IMAGE_NAME="$1"
AL_TAG="$2"
NAME_FOR_TAG_FILE="$3"

if [[ $IMAGE_NAME == *-builder ]]; then
    # ignore checking builder images
    exit 0
fi

BASE_IMAGE_TAG="$(yq e ".al$AL_TAG.\"$NAME_FOR_TAG_FILE\"" $SCRIPT_ROOT/../EKS_DISTRO_TAG_FILE.yaml)"
BASE_IMAGE=public.ecr.aws/eks-distro-build-tooling/$IMAGE_NAME:$BASE_IMAGE_TAG
mkdir -p check-update

cat << EOF > check-update/Dockerfile
FROM $BASE_IMAGE AS base_image

FROM public.ecr.aws/amazonlinux/amazonlinux:$AL_TAG as builder

RUN rm -rf /var/lib/rpm
COPY --from=base_image /var/lib/rpm /var/lib/rpm
COPY --from=base_image /etc/yum.repos.d /etc/yum.repos.d

RUN set -x && \
    if grep -q "2023" "/etc/os-release"; then \
        yum check-update --security --releasever=latest  > ./check_update_output; echo \$? > ./return_value; \
    else \
        yum check-update --security  > ./check_update_output; echo \$? > ./return_value; \    
    fi && \
    cat ./check_update_output | awk '/^$/,0' | awk '{print \$1}' > ./update_packages

FROM scratch

COPY --from=builder ./return_value ./return_value
COPY --from=builder ./update_packages ./update_packages
EOF

$SCRIPT_ROOT/../scripts/buildkit.sh build --frontend dockerfile.v0 \
         --opt platform=linux/amd64 \
         --opt filename=./check-update/Dockerfile \
         --local context=. \
         --progress plain \
         --output type=local,dest=/tmp/${IMAGE_NAME} \
    || {
            mkdir -p /tmp/${IMAGE_NAME}
            echo "100" > /tmp/${IMAGE_NAME}/return_value
            echo "" > /tmp/${IMAGE_NAME}/update_packages
        }

RETURN_STATUS=$(cat /tmp/${IMAGE_NAME}/return_value)

if [ "$JOB_TYPE" != "periodic" ]; then
    echo "none" > ./check-update/${NAME_FOR_TAG_FILE}
    exit 0
fi

if [ $RETURN_STATUS -eq 100 ]; then
    cat /tmp/${IMAGE_NAME}/update_packages > ${SCRIPT_ROOT}/../eks-distro-base-updates/${AL_TAG}/update_packages-${NAME_FOR_TAG_FILE}
    echo "updates" > ./check-update/${NAME_FOR_TAG_FILE}
elif [ $RETURN_STATUS -eq 0 ]; then
    echo "none" > ./check-update/${NAME_FOR_TAG_FILE}
elif [ $RETURN_STATUS -eq 1 ]; then
    echo "error" > ./check-update/${NAME_FOR_TAG_FILE}
fi
