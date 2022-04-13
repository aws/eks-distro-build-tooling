# prow-control-plane chart handling
PROW_GIT_TAG=66078146cd07488dcc190615b709d15f5392fb98
PROW_UPSTREAM_REPO=test-infra
PROW_CLONE_URL=https://github.com/kubernetes/$(PROW_UPSTREAM_REPO).git

GIT_CHECKOUT_TARGET?=$(PROW_UPSTREAM_REPO)/eks-distro-checkout-$(PROW_GIT_TAG)
GIT_PATCH_TARGET?=$(PROW_UPSTREAM_REPO)/eks-distro-patched

PATCHES_DIR=$(CHART_ROOT)/patches/prow-control-plane


$(PROW_UPSTREAM_REPO):
	git clone $(PROW_CLONE_URL) $(PROW_UPSTREAM_REPO)

$(GIT_CHECKOUT_TARGET): | $(PROW_UPSTREAM_REPO)
	@rm -f $(PROW_UPSTREAM_REPO)/eks-distro-*
	git -C $(PROW_UPSTREAM_REPO) checkout -f $(PROW_GIT_TAG)
	touch $@

$(GIT_PATCH_TARGET): $(GIT_CHECKOUT_TARGET)
	git -C $(PROW_UPSTREAM_REPO) config user.email prow@amazonaws.com
	git -C $(PROW_UPSTREAM_REPO) config user.name "Prow Bot"
	git -C $(PROW_UPSTREAM_REPO) am --committer-date-is-author-date $(PATCHES_DIR)/*
	@touch $@

# Copy only template files we care about from upstream into place
prepare-prow-control-plane: $(GIT_PATCH_TARGET)
	rsync -a $(PROW_UPSTREAM_REPO)/config/prow/cluster --files-from=$(CHART_ROOT)/scripts/prow-control-plane-upstream-template-files $(CHART_ROOT)/stable/prow-control-plane/templates
