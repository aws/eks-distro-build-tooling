GRAFANA_CHART_REPO?=helm-charts
GRAFANA_CHART_CLONE_URL?=https://github.com/grafana/$(GRAFANA_CHART_REPO).git
GRAFANA_CHART_GIT_TAG?=grafana-6.13.6

ifeq ("$(GRAFANA_CHART_REPO)","")
	$(error No repository name for Grafana chart was provided.)
endif

ifeq ("$(GRAFANA_CHART_CLONE_URL)","")
	$(error No Grafana chart clone url was provided.)
endif

ifeq ("$(GRAFANA_CHART_GIT_TAG)","")
	$(error No git tag for Grafana chart was provided.)
endif

CHART_SCRIPTS_DIR=$(shell git rev-parse --show-toplevel)/helm-charts/scripts
MAKE_ROOT=$(shell cd "$(dirname "$(BASH_SOURCE[0])")" && pwd -P)
CLONE_ROOT=$(MAKE_ROOT)/helm-charts

.PHONY: clone
clone: clean
	git clone $(GRAFANA_CHART_CLONE_URL) $(GRAFANA_CHART_REPO)
	cd $(GRAFANA_CHART_REPO) && git checkout $(GRAFANA_CHART_GIT_TAG)

.PHONY: install-toolchain
install-toolchain:
	$(CHART_SCRIPTS_DIR)/install-toolchain.sh

verify: install-toolchain clone

.PHONY: publish
publish:
	$(CHART_SCRIPTS_DIR)/publish-charts.sh $(CLONE_ROOT)/charts/grafana

.PHONY: release
release: install-toolchain clone publish

.PHONY: clean
clean:
	rm -rf $(GRAFANA_CHART_REPO)
