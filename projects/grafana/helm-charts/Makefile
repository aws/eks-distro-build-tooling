GRAFANA_CHART_REPO?=helm-charts
GRAFANA_CHART_CLONE_URL?=https://github.com/grafana/$(GRAFANA_CHART_REPO).git
GRAFANA_CHART_GIT_COMMIT=8d97c0351ddd41522c91e3dfb519f1b5317ca1dd

ifeq ("$(GRAFANA_CHART_CLONE_URL)","")
	$(error No Grafana charts clone url was provided.)
endif

ifeq ("$(GRAFANA_CHART_REPO)","")
	$(error No repository name for Grafana charts were provided.)
endif

ifeq ("$(GRAFANA_CHART_GIT_COMMIT)","")
	$(error No git commit for Grafana chart repo was provided.)
endif

CHART_BUILD_DIR=$(shell git rev-parse --show-toplevel)/helm-charts/build
CHART_SCRIPTS_DIR=$(shell git rev-parse --show-toplevel)/helm-charts/scripts
MAKE_ROOT=$(shell cd "$(dirname "$(BASH_SOURCE[0])")" && pwd -P)
CLONE_ROOT=$(MAKE_ROOT)/helm-charts

.PHONY: clone
clone: clean
	git clone $(GRAFANA_CHART_CLONE_URL) $(GRAFANA_CHART_REPO)
	cd $(GRAFANA_CHART_REPO) && git checkout $(GRAFANA_CHART_GIT_COMMIT)

.PHONY: install-toolchain
install-toolchain:
	$(CHART_SCRIPTS_DIR)/install-toolchain.sh

verify: install-toolchain clone
	$(CHART_SCRIPTS_DIR)/lint-charts.sh $(CLONE_ROOT)/charts

.PHONY: publish
publish:
	$(CHART_SCRIPTS_DIR)/publish-charts.sh $(CLONE_ROOT)/charts/grafana

.PHONY: release
release: install-toolchain clone publish

.PHONY: clean
clean:
	rm -rf $(GRAFANA_CHART_REPO)
