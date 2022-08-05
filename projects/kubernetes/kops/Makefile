BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/kubernetes/kops
CLONED_REPO_DIRECTORY:=$(PROJECT_DIRECTORY)/kops

KOPS_VERSION_TAG?="v1.23.2"
KOPS_REPO_URL?="https://github.com/kubernetes/kops.git"

ARTIFACTS_BUCKET?=""

.PHONY: build
build: clone-kops patch-nodeup build-nodeup pull-binaries pull-images move-nodeup-binaries

.PHONY: release
release: build sync-artifacts-to-s3

.PHONY: clone-kops
clone-kops:
	git clone $(KOPS_REPO_URL)

.PHONY: patch-nodeup
patch-nodeup:
	git -C $(CLONED_REPO_DIRECTORY) checkout $(KOPS_VERSION_TAG)
	git -C $(CLONED_REPO_DIRECTORY) am ../patches/*

.PHONY: build-nodeup
build-nodeup:
	(cd $(CLONED_REPO_DIRECTORY) && make crossbuild-nodeup)

.PHONY: pull-binaries
pull-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && fetch_kops_binaries

.PHONY: pull-images
pull-images:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && fetch_kops_images

.PHONY: move-nodeup-binaries
move-nodeup-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && move_nodeup_binaries

.PHONY: sync-artifacts-to-s3-dry-run
sync-artifacts-to-s3-dry-run:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(PROJECT_DIRECTORY)/output/kops kops false true


.PHONY: sync-artifacts-to-s3
sync-artifacts-to-s3:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(PROJECT_DIRECTORY)/output/kops kops false false

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)
	rm -rf $(PROJECT_DIRECTORY)/output
