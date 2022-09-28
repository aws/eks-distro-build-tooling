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

sync_artifacts_to_s3() {
  local artifact_bucket=$1
  local src_dir=$2
  local dest_dir=$3
  local public_read=$4
  local dry_run=$5

  if [ $# -le 3 ] ; then
    echo "not enough parameters supplied!"
  fi

  if [ -z "$1" ] ; then
    echo "first parameter, target artifacts s3 bucket, is required!" && exit 1;
  fi

  if [ -z "$2" ] ; then
    echo "second parameter source directory is required!" && exit 1;
  fi

  if [ -z "$3" ] ; then
    echo "third parameter destination directory is required!" && exit 1;
  fi

  if [ -z "$4" ] ; then
    echo "fourth parameter, public read for s3, is required" && exit 1;
  fi

  if [ -z "$5" ] ; then
    echo "this is not a dry run!"
  fi

  public_acl_argument=""
  if [ "$public_read" = "true" ]; then
    public_acl_argument="--acl public-read"
  fi

  if [ "$dry_run" = "true" ]; then
  aws s3 cp $src_dir s3://${artifact_bucket}/${dest_dir} --recursive --dryrun ${public_acl_argument}
    else
  aws s3 sync $src_dir s3://${artifact_bucket}/${dest_dir} ${public_acl_argument}
fi
}
