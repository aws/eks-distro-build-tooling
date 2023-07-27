BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/kubernetes/kops
CLONED_REPO_DIRECTORY:=$(PROJECT_DIRECTORY)/kops
CLONED_REPO_PATCHES_DIRECTORY:=$(CLONED_REPO_DIRECTORY)/patches

KOPS_VERSION_TAG?=$(shell cat $(PROJECT_DIRECTORY)/GIT_TAG)
KOPS_REPO_URL?="https://github.com/kubernetes/kops.git"

GITHUB_EMAIL?="prow@amazonaws.com"
GITHUB_USER?="Prow Bot"

export PATH:=/go/go1.19/bin:$(PATH)

.PHONY: build
build: check-env clone-kops patch-kops build-nodeup build-kops pull-binaries pull-images move-nodeup-binaries move-kops-binaries sync-artifacts-to-s3-dry-run

.PHONY: release
release: build sync-artifacts-to-s3

.PHONY: clone-kops
clone-kops:
	git clone $(KOPS_REPO_URL)

.PHONY: patch-kops
patch-kops:
	git -C $(CLONED_REPO_DIRECTORY) config user.email $(GITHUB_EMAIL)
	git -C $(CLONED_REPO_DIRECTORY) config user.name $(GITHUB_USER)
	git -C $(CLONED_REPO_DIRECTORY) checkout $(KOPS_VERSION_TAG)
	if [ "$(ls -A $CLONED_REPO_PATCHES_DIRECTORY)" ]; then git -C $(REPO) am --committer-date-is-author-date $(CLONED_REPO_PATCHES_DIRECTORY)/*; fi

.PHONY: build-nodeup
build-nodeup:
	(cd $(CLONED_REPO_DIRECTORY) && make crossbuild-nodeup)

.PHONY: build-kops
build-kops:
	(cd $(CLONED_REPO_DIRECTORY) && make crossbuild)

.PHONY: pull-binaries
pull-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && fetch_kops_binaries

.PHONY: pull-images
pull-images:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && fetch_kops_images

.PHONY: move-nodeup-binaries
move-nodeup-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && move_nodeup_binaries

.PHONY: move-kops-binaries
move-kops-binaries:
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && move_kops_binaries

.PHONY: sync-artifacts-to-s3-dry-run
sync-artifacts-to-s3-dry-run: check-env
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(PROJECT_DIRECTORY)/output/kops kops true true

.PHONY: sync-artifacts-to-s3
sync-artifacts-to-s3: check-env
	source $(PROJECT_DIRECTORY)/kops_artifacts_management_tools.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(PROJECT_DIRECTORY)/output/kops kops true false

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)
	rm -rf $(PROJECT_DIRECTORY)/output

.PHONY: check-env
check-env:
ifndef ARTIFACTS_BUCKET
$(error environment variable ARTIFACTS_BUCKET is undefined)
endif
