CHART_ROOT ?= $(shell git rev-parse --show-toplevel)/helm-charts
BUILD_DIR ?= $(dir $(realpath -s $(firstword $(MAKEFILE_LIST))))/build
STABLE ?= ${CHART_ROOT}/stable

$(shell mkdir -p ${BUILD_DIR})

all: verify publish

install-toolchain:
	${CHART_ROOT}/scripts/install-toolchain.sh

verify: install-toolchain prepare-prow-control-plane
	${CHART_ROOT}/scripts/lint-charts.sh ${STABLE}
	${CHART_ROOT}/scripts/verify-version.sh ${STABLE}

publish: prepare-prow-control-plane
	${CHART_ROOT}/scripts/publish-charts.sh ${STABLE}

release: install-toolchain publish

clean: clean-test-infra
	rm -rf ${CHART_ROOT}/build/

help:
	@grep -E '^[a-zA-Z_-]+:.*$$' $(MAKEFILE_LIST) | sort

.PHONY: all build verify package help

include Prow.mk
