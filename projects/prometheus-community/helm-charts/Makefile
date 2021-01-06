PROMETHEUS_CHART_REPO?=helm-charts
PROMETHEUS_CHART_CLONE_URL?=https://github.com/prometheus-community/$(PROMETHEUS_CHART_REPO).git

KUBE_STATE_METRICS_CHART_REPO?=kube-state-metrics
KUBE_STATE_METRICS_CHART_CLONE_URL?=https://github.com/kubernetes/$(KUBE_STATE_METRICS_CHART_REPO).git

PROMETHEUS_CHART_GIT_COMMIT=5dc19ca22e6038b98c03e77df4d9b313b642acdb
KUBE_STATE_METRICS_CHART_GIT_COMMIT=ae57d8127e65fe7aff957681e78d8f27b951c24a

ifeq ("$(PROMETHEUS_CHART_CLONE_URL)","")
	$(error No Prometheus charts clone url was provided.)
endif

ifeq ("$(KUBE_STATE_METRICS_CHART_CLONE_URL)","")
	$(error No kube-state-metrics charts url was provided.)
endif

ifeq ("$(PROMETHEUS_CHART_REPO)","")
	$(error No repository name for Prometheus charts were provided.)
endif

ifeq ("$(KUBE_STATE_METRICS_CHART_REPO)","")
	$(error No repository name for kube-state-metrics charts were provided.)
endif

ifeq ("$(PROMETHEUS_CHART_GIT_COMMIT)","")
	$(error No git commit for Prometheus chart repo was provided.)
endif

ifeq ("$(KUBE_STATE_METRICS_CHART_GIT_COMMIT)","")
	$(error No git commit for kube-state-metrics chart repo was provided.)
endif

CHART_BUILD_DIR=$(shell git rev-parse --show-toplevel)/helm-charts/build
CHART_SCRIPTS_DIR=$(shell git rev-parse --show-toplevel)/helm-charts/scripts
MAKE_ROOT=$(shell cd "$(dirname "$(BASH_SOURCE[0])")" && pwd -P)
CLONE_ROOT=$(MAKE_ROOT)/helm-charts

.PHONY: clone
clone: clean
	git clone $(PROMETHEUS_CHART_CLONE_URL) $(PROMETHEUS_CHART_REPO)
	cd $(PROMETHEUS_CHART_REPO) && git checkout $(PROMETHEUS_CHART_GIT_COMMIT)
	# Clone and setup dependency charts for Prometheus
	cd $(PROMETHEUS_CHART_REPO)/charts/prometheus && git clone $(KUBE_STATE_METRICS_CHART_CLONE_URL)
	cd $(PROMETHEUS_CHART_REPO)/charts/prometheus/$(KUBE_STATE_METRICS_CHART_REPO) && git checkout $(KUBE_STATE_METRICS_CHART_GIT_COMMIT)
	mv $(PROMETHEUS_CHART_REPO)/charts/prometheus/$(KUBE_STATE_METRICS_CHART_REPO)/charts $(PROMETHEUS_CHART_REPO)/charts/prometheus/
	rm -rf $(PROMETHEUS_CHART_REPO)/charts/prometheus/$(KUBE_STATE_METRICS_CHART_REPO)

.PHONY: install-toolchain
install-toolchain:
	$(CHART_SCRIPTS_DIR)/install-toolchain.sh

verify: install-toolchain clone
	$(CHART_SCRIPTS_DIR)/lint-charts.sh $(CLONE_ROOT)/charts
	$(CHART_SCRIPTS_DIR)/verify-version.sh $(CLONE_ROOT)/charts

.PHONY: publish
publish:
	$(CHART_SCRIPTS_DIR)/publish-charts.sh $(CLONE_ROOT)/charts/prometheus

.PHONY: release
release: install-toolchain clone publish

.PHONY: clean
clean:
	rm -rf $(PROMETHEUS_CHART_REPO)
