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

function retry() {
	local n=1
	local max=120
	local delay=5
	while true; do
		"$@" && break || {
			if [[ $n -lt $max ]]; then
				((n++))
				sleep $delay
			fi
		}
	done
}

function build::docker::retry_pull() {
	retry docker pull "$@"
}

function build::find::gnu_variant_on_mac() {
	local -r cmd="$1"

	if [ "$(uname -s)" = "Linux" ]; then
		echo "$cmd"
		return
	fi

	local final="$cmd"
	if command -v "g$final" &>/dev/null; then
		final="g$final"
	fi

	if [[ "$final" = "$cmd" ]] && command -v "gnu$final" &>/dev/null; then
		final="gnu$final"
	fi

	if [[ "$final" = "$cmd" ]]; then
		echo >&2 " !!! Building on Mac OS X and GNU '$cmd' not found. Using the builtin version"
		echo >&2 "     *may* work, but in general you should either build on a Linux host or"
		echo >&2 "     install the gnu version via brew, usually 'brew install gnu-$cmd'"
	fi

	echo "$final"
}

