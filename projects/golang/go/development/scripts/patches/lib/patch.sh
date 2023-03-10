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

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
# Arg 2:  absolute path to the root directory of the locally cloned Golang repo
function apply_cve_patches {
  local version_dir=$1
  local golang_dir=$2

  echo "Applying *CVE* patches in $version_dir to $golang_dir..."
  if apply_patches "$version_dir" "$golang_dir" "true"; then
    echo "All *CVE* patches succeeded!"
    echo "HEAD is at the last successful *CVE* patch."
    return 0
  fi
  echo "A *CVE* patch failed to apply"
  echo "HEAD is at the last successful *CVE* patch."
  return 1
}

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
# Arg 2:  absolute path to the root directory of the locally cloned Golang repo
function apply_other_patches {
  local version_dir=$1
  local golang_dir=$2

  echo "Assuming CVE patches, if they exist, are already applied in $golang_dir"

  echo "Applying *other* patches in $version_dir to $golang_dir..."
  if apply_patches "$version_dir" "$golang_dir" "false"; then
    echo "All *other* patches succeeded!"
    echo "HEAD is at the last successful *other* patch."
    return 0
  fi

  echo "An *other* patch failed to apply"
  echo "HEAD is at the last successful *other* patch."
  return 1
}

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
# Arg 2:  absolute path to the root directory of the locally cloned Golang repo
# Arg 3:  must be "true" if the applied patches are CVE patches. All other values indicate that the
#         patches are not CVE patches.
function apply_patches {
  local version_dir=$1
  local golang_dir=$2
  local is_apply_for_cve_patches=$3

  local patches

  pushd "$golang_dir"

  if [[ -n "$(ls "$version_dir")" ]]; then
    patches=$(_get_patches "${version_dir}" "${is_apply_for_cve_patches}")
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

# Arg 1:  absolute path to the root directory of the locally cloned Golang repo
# Arg 2:  upstream Go commit to cherry-pick
function cherry_pick {
  local golang_dir=$1
  local cherry_pick_commit=$2

  pushd "$golang_dir"
  git cherry-pick "$cherry_pick_commit"
  popd
}

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
# Arg 2:  should be "true" if the applied patches are CVE patches. All other values indicate that
#         the patches are not CVE patches.
#
# Returns:  names of patch files
function _get_patches {
  local version_dir=$1
  local is_apply_for_cve_patches_string=$2

  local is_apply_for_cve_patches=false
  if [ "$is_apply_for_cve_patches_string" = "true" ]; then
    is_apply_for_cve_patches=true
  fi

  local file_name_regex
  file_name_regex="^.*[0-9]{4}-$(get_eks_go_git_tag "$version_dir")-.*\.patch$"
  local is_match

  declare -a patches

  for file in "${version_dir}"/patches/*.patch; do
    is_match=false
    if [[ $file =~ $file_name_regex ]]; then
      is_match=true
    fi

    if [ $is_match = $is_apply_for_cve_patches ]; then
      patches+=("$file")
    fi
  done
  echo "${patches[@]}"
}

# Arg 1:  absolute path to the root directory of where the Golang repo is locally cloned or will be
#         locally cloned if it is not already
function clone_golang {
  local golang_dir=$1
  if [ ! "$(ls -A "$golang_dir")" ]; then
    echo "Golang repo expected at $golang_dir but was not found. Cloning..."
    git clone "$GOLANG_GIT_URL" "$golang_dir" --origin upstream
  fi
}

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
# Arg 2:  absolute path to the root directory of the locally cloned Golang repo
function checkout_golang_at_git_tag {
  local version_dir=$1
  local golang_dir=$2

  pushd "$golang_dir"
  if ! git diff-index --quiet HEAD --; then
    echo "Local $golang_dir repository is in a dirty state. Stash, commit, or reset in-progress work."
    popd
    return 1
  fi

  if ! git config remote.upstream.url >/dev/null; then
    git remote add upstream "$GOLANG_GIT_URL"
  fi
  git fetch upstream --tags -f

  local git_tag
  git_tag="$(get_golang_git_tag "${version_dir}")"

  echo "Checking out $git_tag in $golang_dir"
  git checkout tags/"$git_tag"
  echo "$git_tag checked out!"
  popd
}

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
#
# Returns:  EKS Go git tag, e.g. go-1.17.13-eks
function get_eks_go_git_tag {
  local version_dir=$1

  local golang_git_tag
  golang_git_tag=$(get_golang_git_tag "$version_dir")
  echo "${golang_git_tag//go/go-}-eks"
}

# Arg 1:  absolute path to the Golang minor version directory under this repo's projects/golang/go
#
# Returns:  EKS Go git tag, e.g. go1.17.13
function get_golang_git_tag {
  local version_dir=$1

  local version

  pushd "$version_dir" >/dev/null
  version="$(cat GIT_TAG)"
  popd >/dev/null
  echo "$version"
}