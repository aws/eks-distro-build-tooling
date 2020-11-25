#!/usr/bin/env bash

CHART_BUCKET="prowdataclusterstack-prowdataclusterstack-316-prowchartsbucket2e50b8d9-8b0f36hrcee8"
REPO_URL="https://${CHART_BUCKET}.s3.amazonaws.com"

CHART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
STABLE="${CHART_ROOT}/stable"
BUILD_DIR="${CHART_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
export PATH="${TOOLS_DIR}:${PATH}"
