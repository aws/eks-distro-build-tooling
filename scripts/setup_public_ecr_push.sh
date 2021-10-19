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

if [ "$AWS_ROLE_ARN" == "" ]; then
    echo "Empty AWS_ROLE_ARN, this script must be run in a postsubmit pod with IAM Roles for Service Accounts"
    exit 1
fi

if [ "$ECR_PUBLIC_PUSH_ROLE_ARN" == "" ]; then
    echo "Empty ECR_PUBLIC_PUSH_ROLE_ARN, this script must be run in a postsubmit pod with IAM Roles for Service Accounts"
    exit 1
fi

# Creating a config file on the fly to configure assume-role and push to ECR public
cat << EOF > config
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

export AWS_CONFIG_FILE=$(pwd)/config
export AWS_PROFILE=ecr-public-push
export AWS_DEFAULT_PROFILE=$AWS_PROFILE

unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE
