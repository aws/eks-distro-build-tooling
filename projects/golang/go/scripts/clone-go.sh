#!/usr/bin/env bash

set -e
set -o pipefail
set -x

if [[ -d $HOME/repo/go ]]; then
	echo "go already cloned"
else
	mkdir -vp ${HOME}/repo
	git clone https://github.com/golang/go.git ${HOME}/repo/go
fi
