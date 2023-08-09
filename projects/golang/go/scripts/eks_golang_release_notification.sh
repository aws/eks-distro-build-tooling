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

NOTIFICATION_MESSAGE_PATH="projects/golang/go/$GO_SOURCE_VERSION/latest_release.yaml"
NOTIFICATION_SUBJECT="New Release of EKS Golang v$GO_SOURCE_VERSION"

./release_notification.sh "$NOTIFICATION_SUBJECT" "$NOTIFICATION_MESSAGE_PATH" "$SNS_TOPIC_ARN"