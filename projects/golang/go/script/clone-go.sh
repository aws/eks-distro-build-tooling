#!/usr/bin/env bash

set -e
set -o pipefail
set -x

if [[ -d /repo/go ]]; then
	echo "go already cloned"
fi

mkdir -vp ${HOME}/repo

git clone https://github.com/golang/go.git ${HOME}/repo/go
