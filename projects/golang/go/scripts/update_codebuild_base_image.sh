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
set -x

if [ -z "$1" ]; then
    echo "you must specify a codebuild project name"
    exit 1
fi
CODEBUILD_PROJECT_NAME=$1

if [ -z "$2" ]; then
    echo "you must specify an image name"
    exit 1
fi
IMAGE_NAME=$2

if [ -z "$3" ]; then
    echo "you must specify an image tag"
    exit 1
fi
IMAGE_TAG=$3

if [ -z "$4" ]; then
    echo "you must specify an AWS region"
    exit 1
fi
AWS_REGION=$4

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

IMAGE_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG"

aws codebuild update-project \
    --name $CODEBUILD_PROJECT_NAME \
    --environment "{\"image\": \"$IMAGE_URL\", \"type\": \"LINUX_CONTAINER\", \"computeType\": \"BUILD_GENERAL1_LARGE\", \"privilegedMode\": true, \"environmentVariables\": [{\"name\": \"GOPROXY\", \"value\": \"athens-proxy:endpoint\", \"type\": \"SECRETS_MANAGER\"}]}"

