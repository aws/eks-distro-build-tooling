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

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

export SKIP_INSTALL="true"

source $SCRIPT_ROOT/install_aws_cli.sh
source $SCRIPT_ROOT/install_buildkit.sh
source $SCRIPT_ROOT/install_ecr_cred_helper.sh
source $SCRIPT_ROOT/install_gh_cli.sh
source $SCRIPT_ROOT/install_yq.sh
source $SCRIPT_ROOT/install_packer.sh
source $SCRIPT_ROOT/install_nodejs.sh
source $SCRIPT_ROOT/install_helm.sh
source $SCRIPT_ROOT/install_goss.sh
source $SCRIPT_ROOT/install_govc.sh
source $SCRIPT_ROOT/install_hugo.sh
source $SCRIPT_ROOT/install_bash.sh
source $SCRIPT_ROOT/install_upx.sh
source $SCRIPT_ROOT/install_notation.sh
