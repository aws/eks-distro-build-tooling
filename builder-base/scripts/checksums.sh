#!/usr/bin/env bash

GOLANG_VERSION=$1
GOLANG_DOWNLOAD_URL=$2

if [ -z "${GOLANG_DOWNLOAD_URL}" ]; then
  GOLANG_DOWNLOAD_URL="https://golang.org/dl"
fi

echo "Go Version ${GOLANG_VERSION} from ${GOLANG_DOWNLOAD_URL}"
curl -sL -o go${GOLANG_VERSION}.linux-amd64.tar.gz ${GOLANG_DOWNLOAD_URL}/go${GOLANG_VERSION}.linux-amd64.tar.gz
shasum -a 256 go${GOLANG_VERSION}.linux-amd64.tar.gz
rm -f go${GOLANG_VERSION}.linux-amd64.tar.gz
