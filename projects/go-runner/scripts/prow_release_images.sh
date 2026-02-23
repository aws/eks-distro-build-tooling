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

if [ "$ARCHITECTURE" == "ARM64" ]; then
  echo "Won't perform image release for ARM64 arch"
  exit 0
fi

if [ "$AWS_ROLE_ARN" == "" ]; then
  echo "Empty AWS_ROLE_ARN"
  exit 1
fi

if [ "$ECR_PUBLIC_PUSH_ROLE_ARN" == "" ]; then
  echo "Empty ECR_PUBLIC_PUSH_ROLE_ARN"
  exit 1
fi

BASE_DIRECTORY=$(git rev-parse --show-toplevel)
cd ${BASE_DIRECTORY} || exit

cat <<EOF >awscliconfig
[default]
output=json
region=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}
role_arn=$AWS_ROLE_ARN
web_identity_token_file=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

[profile ecr-public-push]
role_arn=$ECR_PUBLIC_PUSH_ROLE_ARN
region=us-east-1
source_profile=default
EOF
export AWS_CONFIG_FILE=$(pwd)/awscliconfig
export AWS_PROFILE=ecr-public-push
unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE


make -C ${BASE_DIRECTORY}/projects/go-runner "release"