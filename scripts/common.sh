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
        sleep $delay;
      fi
    }
  done
}

function build::docker::retry_pull() {
  retry docker pull "$@"
}

function build::common::get_go_path() {
  local -r version=$1

  # This is the path where the specific go binary versions reside in our builder-base image
  local -r gorootbinarypath="/go/go${version}/bin"
  # This is the path that will most likely be correct if running locally
  local -r gopathbinarypath="$GOPATH/go${version}/bin"
  if [ -d "$gorootbinarypath" ]; then
    echo $gorootbinarypath
  elif [ -d "$gopathbinarypath" ]; then
    echo $gopathbinarypath
  else
    # not in builder-base, probably running in dev environment
    # return default go installation
    local -r which_go=$(which go)
    echo "$(dirname $which_go)"
  fi
}

function build::common::use_go_version() {
  local -r version=$1
  local -r GOROOT_CUSTOM=$2

  if (( "${version#*.}" < 16 )); then
    echo "Building with GO version $version is no longer supported!  Please update the build to use a newer version."
    exit 1
  fi

  local gobinarypath
  if [[ -n "$GOROOT_CUSTOM" && -f "$GOROOT_CUSTOM/bin/go" ]]; then
    export GOROOT=$GOROOT_CUSTOM
    gobinarypath=$GOROOT/bin
  else
    echo "Custom GOPATH is not set for job or directory doesn't exist, using system's go"
    gobinarypath=$(build::common::get_go_path $version)
  fi

  local -r gobinarypath=${gobinarypath:=(build::common::get_go_path $version)}
  echo "Adding $gobinarypath to PATH"
  # Adding to the beginning of PATH to allow for builds on specific version if it exists
  export PATH=${gobinarypath}:$PATH
  export GOCACHE=$(go env GOCACHE)/$version
}

function build::gather_licenses() {
  local -r outputdir=$1
  local -r patterns=$2
  local -r golang_version=$3

  # Force deps to only be pulled form vendor directories
  # this is important in a couple cases where license files
  # have to be manually created
  export GOFLAGS=-mod=vendor
  # force platform to be linux to ensure all deps are picked up
  export GOOS=linux 
  export GOARCH=amd64 

  # the version of go used here must be the version go-licenses was installed with corresponding go versions
  build::common::use_go_version $golang_version

  if ! command -v go-licenses &> /dev/null
  then
    echo " go-licenses not found.  If you need license or attribution file handling"
    echo " please refer to the doc in docs/development/attribution-files.md"
    exit
  fi

  mkdir -p "${outputdir}/attribution"
  # attribution file generated uses the output go-deps and go-license to gather the necessary
  # data about each dependency to generate the amazon approved attribution.txt files
  # go-deps is needed for module versions
  # go-licenses are all the dependencies found from the module(s) that were passed in via patterns
  build::common::echo_and_run go list -deps=true -json ./... | jq -s '.'  > "${outputdir}/attribution/go-deps.json"

  # go-licenses can be a bit noisy with its output and lot of it can be confusing 
  # the following messages are safe to ignore since we do not need the license url for our process
  NOISY_MESSAGES="cannot determine URL for|Error discovering license URL|unsupported package host|contains non-Go code|has empty version|vendor.*\.s$"

  build::common::echo_and_run go-licenses save --force $patterns --save_path "${outputdir}/LICENSES" 2> >(grep -vE "$NOISY_MESSAGES")
  
  build::common::echo_and_run go-licenses csv $patterns 2> >(grep -vE "$NOISY_MESSAGES") > "${outputdir}/attribution/go-license.csv"  

  if cat "${outputdir}/attribution/go-license.csv" | grep -q "^vendor\/golang.org\/x"; then
      echo " go-licenses created a file with a std golang package (golang.org/x/*)"
      echo " prefixed with vendor/.  This most likely will result in an error"
      echo " when generating the attribution file and is probably due to"
      echo " to a version mismatch between the current version of go "
      echo " and the version of go that was used to build go-licenses"
      exit 1
  fi

  if cat "${outputdir}/attribution/go-license.csv" | grep -e ",LGPL-" -e ",GPL-"; then
    echo " one of the dependencies is licensed as LGPL or GPL"
    echo " which is prohibited at Amazon"
    echo " please look into removing the dependency"
    exit 1
  fi

  # go-license is pretty eager to copy src for certain license types
  # when it does, it applies strange permissions to the copied files
  # which makes deleting them later awkward
  # this behavior may change in the future with the following PR
  # https://github.com/google/go-licenses/pull/28
  # We can delete these additional files because we are running go mod vendor
  # prior to this call so we know the source is the same as upstream
  # go-licenses is copying this code because it doesnt know if its be modified or not
  chmod -R 777 "${outputdir}/LICENSES"
  find "${outputdir}/LICENSES" -type f \( -name '*.yml' -o -name '*.go' -o -name '*.mod' -o -name '*.sum' -o -name '*gitignore' \) -delete

  # most of the packages show up the go-license.csv file as the module name
  # from the go.mod file, storing that away since the source dirs usually get deleted
  MODULE_NAME=$(go mod edit -json | jq -r '.Module.Path')
  if [ ! -f ${outputdir}/attribution/root-module.txt ]; then
  	echo $MODULE_NAME > ${outputdir}/attribution/root-module.txt
  fi
}

function build::common::echo_and_run() {
  >&2 echo "($(pwd)) \$ $*"
  "$@"
}


