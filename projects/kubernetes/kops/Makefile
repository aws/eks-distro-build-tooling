BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/kubernetes/kops
CLONED_REPO_DIRECTORY:=$(PROJECT_DIRECTORY)/kops

KOPS_VERSION_TAG?="v1.23.2"
KOPS_REPO_URL?="https://github.com/kubernetes/kops.git"
NODEUP_FLANNEL_PLUGIN_PATCH="0001-remove-hardcoded-requierment-on-flannel-plugin.patch"

.PHONY: build
build: clone-kops patch-nodeup build-nodeup pull-binaries pull-images copy-nodeup-binaries

.PHONY: clone-kops
clone-kops:
	git clone $(KOPS_REPO_URL)

.PHONY: patch-nodeup
patch-nodeup:
	git -C $(CLONED_REPO_DIRECTORY) checkout $(KOPS_VERSION_TAG)
	git -C $(CLONED_REPO_DIRECTORY) am ../patches/$(NODEUP_FLANNEL_PLUGIN_PATCH)

.PHONY: build-nodeup
build-nodeup:
	(cd $(CLONED_REPO_DIRECTORY) && make crossbuild-nodeup)

.PHONY: pull-binaries
pull-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && fetch_kops_binaries

.PHONY: pull-images
pull-images:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && fetch_kops_images

.PHONY: copy-nodeup-binaries
copy-nodeup-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && copy_nodeup_binaries

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)
	rm -rf $(PROJECT_DIRECTORY)/output
