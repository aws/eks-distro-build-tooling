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

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

REPO="test-infra"

# Check out upstream test-infra repo which contains upstream chart source
git clone git@github.com:kubernetes/test-infra.git
git -C $REPO checkout 6f0e27831a49cd9ae44e920fe4548b9af5e30c1c

# Patch upstream source templates for eks-a specific changes
git -C $REPO am --committer-date-is-author-date $SCRIPT_ROOT/../patches/prow-control-plane/*

# Copy only template files we care about from upstream into place
rsync -a $REPO/config/prow/cluster --files-from=$SCRIPT_ROOT/prow-control-plane-upstream-template-files stable/prow-control-plane/templates
