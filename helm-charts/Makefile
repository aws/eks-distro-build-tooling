CHART_ROOT ?= $(shell git rev-parse --show-toplevel)/helm-charts
BUILD_DIR ?= $(dir $(realpath -s $(firstword $(MAKEFILE_LIST))))/build

$(shell mkdir -p ${BUILD_DIR})

all: verify publish

install-toolchain:
	${CHART_ROOT}/scripts/install-toolchain.sh

verify: install-toolchain
	${CHART_ROOT}/scripts/lint-charts.sh

publish:
	${CHART_ROOT}/scripts/publish-charts.sh

release: install-toolchain publish

clean:
	rm -rf ${CHART_ROOT}/build/

help:
	@grep -E '^[a-zA-Z_-]+:.*$$' $(MAKEFILE_LIST) | sort

.PHONY: all build verify package help
