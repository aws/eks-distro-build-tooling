#!/usr/bin/env bash

set -e
set -x

BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/golang/go/"
BUILDER_BASE_DIRECTORY="$BASE_DIRECTORY/builder-base"
BUILDER_BASE_VERSIONS_FILE="$BUILDER_BASE_DIRECTORY/versions.yaml"

target_versions=$(yq '.| keys' "$BUILDER_BASE_VERSIONS_FILE" | grep GOLANG | tr -d '-')

for versionstring in $target_versions; do
  echo "updating versions.yaml golang version $versionstring with new value from current git rev..."

  version=${versionstring: -3}
  semver="${version:0:1}.${version:1:2}"

  git_tag_file=$(cat "$PROJECT_DIRECTORY""$semver"/GIT_TAG)
  git_tag="${git_tag_file:2}"

  release=$(cat "$PROJECT_DIRECTORY""$semver"/RELEASE)

  updated_golang_version=$git_tag-$release
  echo "$updated_golang_version"

  export versionstring=$versionstring
  export updated_golang_version=$updated_golang_version

  yq e -i '.[env(versionstring)] = env(updated_golang_version)' "$BUILDER_BASE_VERSIONS_FILE"
done
