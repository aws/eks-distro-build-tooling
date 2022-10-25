#!/usr/bin/env bash

set -e
set -x

BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/golang/go/"

GO_REPO="$(dirname "$BASE_DIRECTORY")/go"

GO_VERSIONS=('1.15.15', '1.16.15', '1.17.13')

clone-go() {
	if [[ ! -e $GO_REPO ]]; then
		git clone "$GO_REPO_URL" "$(dirname "$GO_REPO")"
	fi
}

create-eks-patch-branches() {
	for ver in "${GO_VERSION[@]}"; do
		git checkout "release-branch.go${ver:0:4}"
		git checkout -B "go-$ver-eks"
		git am $PROJECTS_DIRECTORY/${ver:0:4}/patches/*.patch
	done	
}

cherry-pick-commit() {
	git cherry-pick $1
}

create-patch() {
	echo "create patch"
}

remove-golang-repo() {
	echo "remove go repo"
}
