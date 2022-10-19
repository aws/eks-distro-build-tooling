#!/usr/bin/env bash

set -e
set -o pipefail
set -x

GO_VERSIONS=('1.15.15' '1.16.15' '1.17.13')
GO_REPO=$HOME/repo/go
BASE_DIR="$(dirname "$(pwd)")"

cd $GO_REPO

for ver in "${GO_VERSIONS[@]}"; do
	git checkout "release-branch.go${ver:0:4}"
	git checkout -B "go-$ver-eks"
	git am $BASE_DIR/${ver:0:4}/patches/*.patch
done
