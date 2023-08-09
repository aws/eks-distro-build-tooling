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

notification_subject="$1"
notification_message_path="$2"
sns_topic_arn="$3"

base_directory=$(git rev-parse --show-toplevel)
notification_message="$(cat $base_directory/$notification_message_path)"

sns_message_id=$(
  aws sns publish \
    --topic-arn "$sns_topic_arn" \
    --subject "$notification_subject" \
    --message "$notification_message" \
    --query "MessageId" --output text
)

if [ "$sns_message_id" ]; then
  echo -e "\nRelease notification published with SNS MessageId $sns_message_id"
else
  echo -e "Received unexpected response while publishing to release SNS topic $SNS_TOPIC_ARN. \
An error may have occurred, and the notification may not have been published"
  exit 1
fi
