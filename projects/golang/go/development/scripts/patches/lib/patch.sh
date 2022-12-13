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

GOLANG_GIT_URL="https://github.com/golang/go.git"

function clone_golang {
  local golang_dir=$1
  if [ ! "$(ls -A "$golang_dir")" ]; then
    echo "Golang repo expected at $golang_dir but was not found. Cloning..."
    git clone "$GOLANG_GIT_URL" "$golang_dir" --origin upstream
  fi
}

function check_dirty {
  local golang_dir=$1
  pushd "$golang_dir"
  if ! git diff-index --quiet HEAD --; then
    echo "Local $golang_dir repository is in a dirty state. Stash, commit, or reset in-progress work."
    popd
    return 1
  fi
  popd
}

function apply_cve_patches {
  local version_dir=$1
  local golang_dir=$2

  local git_tag
  git_tag="$(get_golang_git_tag "${version_dir}")"

  echo "Checking out $git_tag in $golang_dir"
  checkout_golang "$git_tag" "$golang_dir"
  echo "$git_tag checked out!"

  echo "Applying patches in $version_dir to $golang_dir..."
  if apply_patches "$version_dir" "$golang_dir" "true"; then
    echo "All patches succeeded!"
    echo "HEAD is at the last successful patch."
    return 0
  fi
  echo "A patch failed!"
  echo "HEAD is at the last successful patch."
  return 1
}

function apply_other_patches {
  local version_dir=$1
  local golang_dir=$2

echo "Assuming previous patches are already applied in $golang_dir"

  echo "Applying patches in $version_dir to $golang_dir..."
  if apply_patches "$version_dir" "$golang_dir" "false"; then
    echo "All patches succeeded!"
    echo "HEAD is at the last successful patch."
    return 0
  fi

  echo "A patch failed!"
  echo "HEAD is at the last successful patch."
  return 1
}

function apply_patches {
  local version_dir=$1
  local golang_dir=$2
  local is_apply_for_cve_patches=$3

  local patches

  pushd "$golang_dir"

  if [[ -n "$(ls "$version_dir")" ]]; then
    patches=$(get_patches "${version_dir}" "${is_apply_for_cve_patches}")
    echo "Patches to apply: ${patches}"
    for file in ${patches}; do
      if git am <"$file"; then
        echo "Applying succeeded: $file"
      else
        echo "Applying failed: $file"
        git am --skip
        popd
        return 1
      fi
    done
  else
    echo "Nothing to apply in $version_dir"
  fi

  popd
}

function get_patches {
  local version_dir=$1
  local is_apply_for_cve_patches_string=$2

  local is_apply_for_cve_patches=false
  if [ "$is_apply_for_cve_patches_string" = "true" ]; then
    is_apply_for_cve_patches=true
  fi

  local file_name_regex
  file_name_regex="^.*[0-9]{4}-$(get_eks_go_id "$version_dir")-.*\.patch$"
  local is_match

  declare -a patches

  for file in "${version_dir}"/patches/*.patch; do
    is_match=false
    if [[ $file =~ $file_name_regex ]]; then
      is_match=true
    fi

    if [ $is_match = $is_apply_for_cve_patches ]; then patches+=("$file")
    fi
  done
  echo "${patches[@]}"
}

function checkout_golang {
  local git_tag=$1
  local golang_dir=$2

  pushd "$golang_dir"

  if ! git config remote.upstream.url >/dev/null; then
    git remote add upstream "$GOLANG_GIT_URL"
  fi

  git fetch upstream --tags -f
  git checkout tags/"$git_tag"

  popd
}

function get_eks_go_id {
  local version_dir=$1

  local golang_git_tag
  golang_git_tag=$(get_golang_git_tag "$version_dir")

  echo "${golang_git_tag//go/go-}-eks"
}

# TODO: rename func
function get_golang_git_tag {
  local version_dir=$1

  local version

  pushd "$version_dir" > /dev/null
  version="$(cat GIT_TAG)"
  popd > /dev/null
  echo "$version"
}
