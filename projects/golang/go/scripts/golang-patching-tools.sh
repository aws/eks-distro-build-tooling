#!/usr/bin/env bash

set -e
set -x

BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/golang/go/"

GO_REPO="$(dirname "$BASE_DIRECTORY")/go"

clone-go() {
	if [[ ! -e $GO_REPO ]]; then
		git clone "$GO_REPO_URL" "$(dirname "$GO_REPO")"
	fi
}

create-eks-patch-branches() {
	echo "create-eks-patch-branches"
}

cherry-pick-commit() {
	echo "cherry-pick-commit"
}

create-patch() {
	echo "create patch"
}

remove-golang-repo() {
	echo "remove go repo"
}
