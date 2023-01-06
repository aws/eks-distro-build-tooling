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

set -o errexit
set -o nounset
set -o pipefail

MAKE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

NL=$'\n'
HEADER="########### DO NOT EDIT #############################"
FOOTER="########### END GENERATED ###########################"

MAKEFILE=$MAKE_ROOT/Makefile
HELPFILE=$MAKE_ROOT/Help.mk

SED=sed
if [ "$(uname -s)" = "Darwin" ]; then
    SED=gsed
fi

$SED -i "/$HEADER/,/$FOOTER/d" $MAKEFILE
# remove trailing newlines
printf %s "$(< $MAKEFILE)" > $MAKEFILE

touch $HELPFILE

$SED -i "/$HEADER/,/$FOOTER/d" $HELPFILE
# remove trailing newlines
printf %s "$(< $HELPFILE)" > $HELPFILE


VARIANTS=$(make --no-print-directory -C $MAKE_ROOT var-value-MINIMAL_VARIANTS)
VARIANTS=(${VARIANTS// / })

MAIN_MINIMAL_TARGETS="${NL}${NL}##@ Main Minimal Targets"
EXPORT_MINIMAL_TARGETS="${NL}${NL}##@ Package Export Minimal Targets"
VALIDATE_MINIMAL_TARGETS="${NL}${NL}##@ Validate Minimal Targets"
TEST_MINIMAL_TARGETS="${NL}${NL}##@ Test Minimal Targets"
UPDATE_MINIMAL_TARGETS="${NL}${NL}##@ Update Minimal Targets"
CREATE_PR_MINIMAL_TARGETS="${NL}${NL}##@ Create PR Minimal Targets"

for variant in "${VARIANTS[@]}"; do
    MAIN_MINIMAL_TARGETS+="${NL}minimal-images-${variant}: ## Build, export packages, validate and run tests for minimal variant \`${variant}\`"
    EXPORT_MINIMAL_TARGETS+="${NL}packages-export-minimal-images-${variant}: ## Export packages for minimal variant \`${variant}\`"
    VALIDATE_MINIMAL_TARGETS+="${NL}validate-minimal-images-${variant}: ## Validate for minimal variant \`${variant}\`"
    TEST_MINIMAL_TARGETS+="${NL}test-minimal-images-${variant}: ## Run tests for minimal variant \`${variant}\`"
    UPDATE_MINIMAL_TARGETS+="${NL}minimal-update-${variant}: ## Run update logic for minimal variant \`${variant}\`"
    CREATE_PR_MINIMAL_TARGETS+="${NL}minimal-create-pr-${variant}: ## Run create pr logic for minimal variant \`${variant}\`"
done

COMPILERS_TARGETS="${NL}${NL}##@ Compiler Images Targets"
COMPILERS=$(make --no-print-directory -C $MAKE_ROOT var-value-COMPILERS)
COMPILERS=(${COMPILERS// / })
for compiler in "${COMPILERS[@]}"; do
    COMPILERS_TARGETS+="${NL}${compiler}-compiler-images: ## Build compiler images for all versions of ${compiler}"
    VERSIONS=$(make --no-print-directory -C $MAKE_ROOT var-value-BASE_${compiler^^}_VARIANT_VERSIONS)
    VERSIONS=(${VERSIONS// / })
    for version in "${VERSIONS[@]}"; do
        COMPILERS_TARGETS+="${NL}${compiler}-${version}-compiler-images: ## Build compiler images for ${compiler}-${version}"
    done
done

cat >> $HELPFILE << EOF
${NL}${NL}${NL}${HEADER}
# To update call: make add-generated-help-block
# This is added to help document dynamic targets and support shell autocompletion
${MAIN_MINIMAL_TARGETS}${EXPORT_MINIMAL_TARGETS}${VALIDATE_MINIMAL_TARGETS}${TEST_MINIMAL_TARGETS}${UPDATE_MINIMAL_TARGETS}${CREATE_PR_MINIMAL_TARGETS}${COMPILERS_TARGETS}

${FOOTER}
EOF

cat >> $MAKEFILE << EOF
${NL}${NL}${NL}${HEADER}
# To update call: make add-generated-help-block
# This is added to help document dynamic targets and support shell autocompletion
# Run make help for a formatted help block with all targets
include Help.mk
${FOOTER}
EOF
