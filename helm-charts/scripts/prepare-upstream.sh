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
UPSTREAM_DIR="${SCRIPT_ROOT}/../upstream"
STABLE_DIR="${SCRIPT_ROOT}/../stable"
BUILD_DIR="${SCRIPT_ROOT}/../build/upstream"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

for chart_dir in "${UPSTREAM_DIR}"/*/; do
  chart_name=$(basename "${chart_dir}")
  git_tag=$(cat "${chart_dir}/GIT_TAG" | tr -d '[:space:]')
  repo=$(cat "${chart_dir}/REPO" | tr -d '[:space:]')
  chart_path=$(cat "${chart_dir}/CHART_PATH" | tr -d '[:space:]')

  echo "Preparing ${chart_name} from ${repo}@${git_tag}"
  git clone --depth 1 --branch "${git_tag}" "${repo}" "${BUILD_DIR}/${chart_name}" 2>/dev/null
  cp -r "${BUILD_DIR}/${chart_name}/${chart_path}" "${STABLE_DIR}/${chart_name}"

  if [ -d "${chart_dir}/patches" ]; then
    for patch in "${chart_dir}"/patches/*.patch; do
      [ -f "${patch}" ] || continue
      echo "  Applying patch: $(basename ${patch})"
      cd "${STABLE_DIR}/${chart_name}"
      patch -p3 < "${patch}"
      cd - >/dev/null
    done
  fi
done

rm -rf "${BUILD_DIR}"
echo "✅ Upstream charts prepared"
