BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
GIT_TAG?=$(shell cat ./$(GO_SOURCE_VERSION)/GIT_TAG)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/golang/go
VERSION_DIRECTORY:=$(PROJECT_DIRECTORY)/$(GO_SOURCE_VERSION)
CLONED_REPO_DIRECTORY:=$(VERSION_DIRECTORY)/go

GO_VERSION_TAG?=$(shell cat $(VERSION_DIRECTORY)/GIT_TAG)
GO_REPO_URL?="https://github.com/golang/go.git"

GITHUB_EMAIL?="prow@amazonaws.com"
GITHUB_USER?="Prow Bot"

.PHONY: build
build: check-env setup-rpm-tree fetch-golang-source-archive copy-sources-to-rpmbuild-tree copy-patches-to-rpmbuild-tree build-golang-rpm sync-artifacts-to-s3-dry-run

.PHONY: release
release: build sync-artifacts-to-s3

.PHONY: fetch-golang-source-archive
fetch-golang-source-archive:
	curl -L -o $(HOME)/rpmbuild/SOURCES/$(GIT_TAG).src.tar.gz https://github.com/golang/go/archive/refs/tags/$(GIT_TAG).tar.gz --create-dirs 

.PHONY: copy-patches-to-rpmbuild-tree
copy-patches-to-rpmbuild-tree:
	cp -r $(VERSION_DIRECTORY)/patches/* $(HOME)/rpmbuild/SOURCES/

.PHONY: copy-sources-to-rpmbuild-tree
copy-sources-to-rpmbuild-tree:
	cp -r $(VERSION_DIRECTORY)/rpmbuild/SOURCES/* $(HOME)/rpmbuild/SOURCES/

.PHONY: setup-rpm-tree
setup-rpm-tree:
ifeq (, $(shell which rpmdev-setuptree))
	$(error "no rpmdev-setuptree in $(PATH); get it with 'yum install rpmdevtools'")
endif
	rpmdev-setuptree

.PHONY: build-golang-rpm
build-golang-rpm:
ifeq ($(shell uname),Darwin)
	$(error "rpmbuild is being run on a Mac, build this on an Amazon Linux machine!")
endif
ifeq (, $(shell which rpmbuild))
	$(error "No rpmbuild in $(PATH), try 'yum install rpmbuild'")
endif
	rpmbuild -ba $(VERSION_DIRECTORY)/rpmbuild/SPECS/golang.spec --define "_rpmdir $(VERSION_DIRECTORY)/rpmbuild"

.PHONY: sync-artifacts-to-s3-dry-run
sync-artifacts-to-s3-dry-run: check-env-release
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/rpmbuild/RPMS golang/go/$(GIT_TAG)/RPMS true true

.PHONY: sync-artifacts-to-s3
sync-artifacts-to-s3: check-env-release
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/rpmbuild/RPMS golang/go/$(GIT_TAG)/RPMS true false

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/noarch
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/x86_64
	rm -rf $(HOME)/rpmbuild

.PHONY: install-deps
install-deps:
	yum update -y && yum install -y which git rpmdevtools awscli rpm-build golang-1.15.14-1.amzn2.0.1 pcre-devel glibc-static hostname procps-ng

.PHONY: check-env-release
check-env-release:
ifndef ARTIFACTS_BUCKET
$(error environment variable ARTIFACTS_BUCKET is undefined)
endif

.PHONY: check-env
check-env:
ifndef GO_SOURCE_VERSION
$(error environment variable GO_SOURCE_VERSION, e.g. 1.15, is undefined)
endif
