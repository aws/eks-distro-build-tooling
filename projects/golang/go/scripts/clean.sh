#!/usr/bin/env bash

set -e
set -o pipefail
set -x

if [[ -d $HOME/repo/go ]]; then
	rm -rv $HOME/repo/go
fi
