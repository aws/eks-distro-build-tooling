AWS_FOR_FLUENT_BIT_CHART_REPO_URL?=https://github.com/aws/eks-charts/
AWS_FOR_FLUENT_BIT_CHART_REPO?=eks-charts
AWS_FOR_FLUENT_BIT_CHART_GIT_TAG?=v0.0.41

ifeq ("$(AWS_FOR_FLUENT_BIT_CHART_REPO_URL)","")
        $(error No repository URL was provided.)
endif

ifeq ("$(AWS_FOR_FLUENT_BIT_CHART_REPO)","")
	$(error No repository name was provided.)
endif

ifeq ("$(AWS_FOR_FLUENT_BIT_CHART_GIT_TAG)","")
	$(error No gittag was provided.)
endif

CHART_SCRIPTS_DIR=$(shell git rev-parse --show-toplevel)/helm-charts/scripts
MAKE_ROOT=$(shell cd "$(dirname "$(BASH_SOURCE[0])")" && pwd -P)
CLONE_ROOT=$(MAKE_ROOT)/$(AWS_FOR_FLUENT_BIT_CHART_REPO)

.PHONY: clone
clone: clean
	git clone  $(AWS_FOR_FLUENT_BIT_CHART_REPO_URL) $(AWS_FOR_FLUENT_BIT_CHART_REPO)
	cd $(AWS_FOR_FLUENT_BIT_CHART_REPO) && git checkout $(AWS_FOR_FLUENT_BIT_CHART_GIT_TAG)

.PHONY: install-toolchain
install-toolchain:
	$(CHART_SCRIPTS_DIR)/install-toolchain.sh

verify: install-toolchain clone
	$(CHART_SCRIPTS_DIR)/lint-charts.sh $(CLONE_ROOT)/stable

.PHONY: publish
publish:
	$(CHART_SCRIPTS_DIR)/publish-charts.sh $(CLONE_ROOT)/stable/aws-for-fluent-bit

.PHONY: release
release: install-toolchain clone publish

.PHONY: clean
clean:
	rm -rf $(AWS_FOR_FLUENT_BIT_CHART_REPO)
