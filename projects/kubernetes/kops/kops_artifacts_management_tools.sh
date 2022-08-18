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

BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/kubernetes/kops"

OUTPUT_DIR="$PROJECT_DIRECTORY/output/kops"

KOPS_VERSION_TAG="1.23.2"

KOPS_BINARIES_BASE_URL="https://artifacts.k8s.io/binaries/kops"
CHANNELS_BINARY="channels"
PROTOKUBE_BINARY="protokube"
KOPS_BINARIES=("$CHANNELS_BINARY" "$PROTOKUBE_BINARY")

DNS_CONTROLLER="dns-controller"
KOPS_CONTROLLER="kops-controller"
KUBE_APISERVER_HEALTHCHECK="kube-apiserver-healthcheck"
KOPS_IMAGES=("$DNS_CONTROLLER" "$KOPS_CONTROLLER" "$KUBE_APISERVER_HEALTHCHECK")

SUPPORTED_ARCHS=("arm64" "amd64")
SUPPORTED_PLATFORMS=("linux")

SHA_SUFFIX=".sha256"
TARBALL_SUFFIX=".tar.gz"

fetch_kops_binaries() {
  for BINARY in "${KOPS_BINARIES[@]}"
  do
    for ARCH in "${SUPPORTED_ARCHS[@]}"
    do
      for PLATFORM in "${SUPPORTED_PLATFORMS[@]}"
      do
          local kops_artifacts_output_dir="$OUTPUT_DIR/$KOPS_VERSION_TAG/$PLATFORM/$ARCH"
          local release_artifact_url="$KOPS_BINARIES_BASE_URL/$KOPS_VERSION_TAG/$PLATFORM/$ARCH/$BINARY"
          local release_artifact_checksum_url="${release_artifact_url}${SHA_SUFFIX}"
          curl -L --create-dirs -o "$kops_artifacts_output_dir/$BINARY" "$release_artifact_url"
          curl -L --create-dirs -o "$kops_artifacts_output_dir/${BINARY}${SHA_SUFFIX}" "$release_artifact_checksum_url"
      done
    done
  done
}

fetch_kops_images() {
  for IMAGE in "${KOPS_IMAGES[@]}"
  do
      for ARCH in "${SUPPORTED_ARCHS[@]}"
      do
        local image_name="$IMAGE-${ARCH}${TARBALL_SUFFIX}"
        local image_output_dir="$OUTPUT_DIR/$KOPS_VERSION_TAG/images"
        local image_url="$KOPS_BINARIES_BASE_URL/$KOPS_VERSION_TAG/images/$image_name"
        local image_checksum_url="${image_url}${SHA_SUFFIX}"
        curl -L --create-dirs -o "$image_output_dir/$image_name" "$image_url"
        curl -L --create-dirs -o "$image_output_dir/${image_name}${SHA_SUFFIX}" "$image_checksum_url"
      done
  done
}

move_nodeup_binaries() {
  for ARCH in "${SUPPORTED_ARCHS[@]}"
  do
    for PLATFORM in "${SUPPORTED_PLATFORMS[@]}"
    do
      local binary_path="$PROJECT_DIRECTORY/kops/.build/dist/$PLATFORM/$ARCH/nodeup"
      local binary_upload_path="$OUTPUT_DIR/$KOPS_VERSION_TAG/$PLATFORM/$ARCH/nodeup"
      cp "$binary_path" "$binary_upload_path"
      # While we're in here, we generate the checksums for the nodeup binaries and output them to the output dir
      sha256sum "$binary_path" | cut -d " " -f 1 >> "${binary_upload_path}${SHA_SUFFIX}"
    done
  done
}

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