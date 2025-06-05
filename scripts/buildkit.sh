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

BUILD_LIB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd -P)"

if [ "${USE_BUILDX:-}" == "true" ]; then
    printf "\nBuilding with with docker buildx\n" >&2

    CMD="docker buildx"
    ARGS=""
    while test $# -gt 0; do
        case "$1" in
            --frontend)
                shift
                shift
                ;;
            --opt)
                shift
                if [[ $1 = filename* ]]; then
                    ARGS+="--${1/filename/file} "
                elif [[ $1 = "no-cache"* ]]; then
                    ARGS+="--${1/no-cache/no-cache-filter} "
                else
                    ARGS+="--${1/:/ } "
                fi
                shift
                ;;
            --local)
                shift
                if [[ $1 = context* ]]; then
                    ARGS+="${1/context=/} "        
                fi
                shift
                ;;
            --export-cache)
                shift
                ARGS+="--cache-to $1 "
                shift
                ;;
            --import-cache)
                shift
                ARGS+="--cache-from $1 "
                shift
                ;;
            *)
                ARGS+="$1 "
                shift
                ;;
        esac
    done
else
    printf "\nBuilding with buildctl\n" >&2

    CMD="buildctl"
    ARGS="$@"
fi

if [ -f "/buildkit.sh" ] && ! buildctl debug workers >/dev/null 2>&1; then
    # on the builder base this helper file exists to run buildkitd
    # in prow buildkitd is run as a seperate container so it will be running already
    # in codebuild its run directly on the instance so we want to use this helper
    CMD="/buildkit.sh"
fi

# From time to time we see random failures when creating/pushing images that fix on reruning the job
# this is an attempt to avoid failing key jobs, like the release job, with a flaky failure
# If running in builder base, most likely we are running in prow/codebuild, us retry logic
# if not in builder base, probably running locally so skip the retry
if [ -f "/buildkit.sh" ]; then
    log_file=$(mktemp)
    trap "rm -f $log_file" EXIT
    for i in $(seq 1 5); do
	[ $i -gt 1 ] && sleep 15
	$CMD $ARGS | tee $log_file
	s=${PIPESTATUS[0]}
	# builkit is not returning non-zero exit code on httpReadSeeker
	if grep -q "ERROR: httpReadSeeker" $log_file ; then
            echo "******************************************************"
            echo "Encountered ERROR: httpReadSeeker, retrying image build"
            echo "******************************************************"
            s=1
        fi
        [ $s == 0 ] && break
    done

    # space is limited on presubmit nodes, after each image build clear the build cache
    if [ "${JOB_TYPE:-}" == "presubmit" ] && [ "${PRUNE_BUILDCTL:-false}" == "true" ]; then
        buildctl prune --all >&2
    fi

    (exit $s)
else
    # skip retry when running locally
    log_file=$(mktemp)
    trap "rm -f $log_file" EXIT
    if ! $CMD $ARGS 2>&1 | tee $log_file; then        
        if grep -q "blobs/uploads/\": EOF" $log_file ; then
            echo "******************************************************"
            echo "Ensure container registry and repository exists!!"
            echo "Try running make create-ecr-repos to create ecr repositories in your aws account."
            echo "******************************************************"
        fi
        exit 1
    fi
fi
