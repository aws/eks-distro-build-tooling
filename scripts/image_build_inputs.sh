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

LABEL_KEY="eks-distro-build-tooling.build-inputs"
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"

function hash_inputs() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --file)
        if [ ! -f "$2" ]; then
          echo "Build input file $2 does not exist" >&2
          exit 1
        fi
        echo "file:$(realpath --relative-to="$REPO_ROOT" "$2"):$(sha256sum < "$2" | cut -d' ' -f1)"
        ;;
      --value)
        if [ -z "$2" ]; then
          echo "Build input value is empty" >&2
          exit 1
        fi
        echo "value:$2"
        ;;
      *)
        echo "Unknown hash argument $1, expected --file or --value" >&2
        exit 1
        ;;
    esac
    shift 2
  done | sha256sum | cut -d' ' -f1
}

function image_label() {
  local config error error_file
  error_file=$(mktemp)
  if ! config=$(oras manifest fetch-config --platform linux/amd64 "$1" 2>"$error_file"); then
    error=$(cat "$error_file")
    rm -f "$error_file"
    if echo "$error" | grep -qiE "not found|manifest unknown"; then
      echo "$1 does not exist, treating it as unbuilt" >&2
      return 0
    fi
    echo "Could not read the config of $1: $error" >&2
    return 1
  fi
  rm -f "$error_file"
  echo "$config" | jq -r --arg key "$LABEL_KEY" '.config.Labels[$key] // empty'
}

COMMAND="$1"
shift

case "$COMMAND" in
  hash) hash_inputs "$@" ;;
  label) image_label "$1" ;;
  key) echo "$LABEL_KEY" ;;
  *) echo "Unknown command $COMMAND"; exit 1 ;;
esac
