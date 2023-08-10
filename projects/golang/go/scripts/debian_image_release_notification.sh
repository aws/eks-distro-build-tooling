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

if [ "$SNS_TOPIC_ARN" == "" ]; then
    echo "Empty SNS_TOPIC_ARN"
    exit 1
fi

if [ "$GO_SOURCE_VERSION" == "" ]; then
    echo "Empty GO_SOURCE_VERSION"
    exit 1
fi

BASE_DIRECTORY=$(git rev-parse --show-toplevel)

GOLANG_TRACKING_TAG="$(cat $BASE_DIRECTORY/projects/golang/go/$GO_SOURCE_VERSION/GIT_TAG)"
EKS_GOLANG_RELEASE_NUMBER="$(cat $BASE_DIRECTORY/projects/golang/go/$GO_SOURCE_VERSION/RELEASE)"
DEBIAN_BASE_RELEASE_NUMBER="$(cat $BASE_DIRECTORY/projects/golang/go/docker/debianBase/RELEASE)"
DEBIAN_BASE_RELEASE_IMAGE_TAG="$GOLANG_TRACKING_TAG-$EKS_GOLANG_RELEASE_NUMBER-$DEBIAN_BASE_RELEASE_NUMBER"

SNS_MESSAGE="golang:
  tracking_tag: $GOLANG_TRACKING_TAG
  eks_golang_number: $EKS_GOLANG_RELEASE_NUMBER
debian_base_release:
  number: $DEBIAN_BASE_RELEASE_NUMBER
  image_tag: $DEBIAN_BASE_RELEASE_IMAGE_TAG
  image_uri: public.ecr.aws/eks-distro-build-tooling/golang-debian:$DEBIAN_BASE_RELEASE_IMAGE_TAG"

SNS_MESSAGE_ID=$(
  aws sns publish \
    --topic-arn "$SNS_TOPIC_ARN" \
    --subject "New Debian Base Image for v$GO_SOURCE_VERSION" \
    --message "$SNS_MESSAGE"\
    --query "MessageId" --output text
)

if [ "$SNS_MESSAGE_ID" ]; then
  echo -e "\nDebian base image release notification published with SNS MessageId $SNS_MESSAGE_ID"
else
  echo -e "Received unexpected response while publishing to Debian base image release SNS topic $SNS_TOPIC_ARN. \
An error may have occurred, and the notification may not have been published"
  exit 1
fi
