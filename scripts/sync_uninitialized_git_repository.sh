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

if [ -z $1 ]; then
    echo "You must provide a working directory in which to execute the git synchronization"
    exit 0
fi

if [ -z $2 ]; then
    echo "You must provide a remote url to synchronize against"
    exit 1
fi

if [ -z $3 ]; then
    echo "No target branch specified; defaulting to 'main'"
    BRANCH=main
else
    BRANCH=$3
fi

git -C $1 init
git -C $1 remote add origin $2
git -C $1 fetch origin
git -C $1 reset --hard origin/$BRANCH
