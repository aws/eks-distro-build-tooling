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
build: check-env clone-golang patch-golang build-golang build-golang-rpm

.PHONY: clone-golang
clone-golang:
	git -C $(VERSION_DIRECTORY) clone $(GO_REPO_URL)

.PHONY: patch-golang
patch-golang:
	git -C $(CLONED_REPO_DIRECTORY) config user.email $(GITHUB_EMAIL)
	git -C $(CLONED_REPO_DIRECTORY) config user.name $(GITHUB_USER)
	git -C $(CLONED_REPO_DIRECTORY) checkout $(GO_VERSION_TAG)
	git -C $(CLONED_REPO_DIRECTORY) am --committer-date-is-author-date $(VERSION_DIRECTORY)/patches/*

.PHONY: build-golang
build-golang:
	(cd $(CLONED_REPO_DIRECTORY)/src && ./all.bash)

.PHONY: build-golang-rpm
build-golang-rpm: fetch-golang-source-archive copy-patches-to-rpmbuild-tree rpmbuild-golang

.PHONY: fetch-golang-source-archive
fetch-golang-source-archive:
	curl -L -o $(VERSION_DIRECTORY)/rpmbuild/SOURCES/$(GIT_TAG).src.tar.gz https://github.com/golang/go/archive/refs/tags/$(GIT_TAG).tar.gz --create-dirs 

.PHONY: copy-patches-to-rpmbuild-tree
copy-patches-to-rpmbuild-tree:
	cp -r $(VERSION_DIRECTORY)/patches/* $(VERSION_DIRECTORY)/rpmbuild/SOURCES/

.PHONY: rpmbuild-golang
rpmbuild-golang:
ifeq ($(shell uname),Darwin)
	$(error "rpmbuild is being run on a Mac, build this on an Amazon Linux machine!")
endif
ifeq (, $(shell which rpmbuild))
	$(error "No rpmbuild in $(PATH), try 'yum install rpmbuild'")
endif
	rpmbuild -ba $(VERSION_DIRECTORY)/rpmbuild/SPECS/golang.spec --define "_topdir $(VERSION_DIRECTORY)/rpmbuild" --define "_tmpdir $(VERSION_DIRECTORY)/rpmbuild/tmp)" --define "_rpmdir $(VERSION_DIRECTORY)/rpmbuild"

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/noarch
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/x86_64
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/SRPMS
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/BUILD
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/BUILDROOT
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/tmp
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/SOURCES/*.patch
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/SOURCES/go-$(GIT_TAG)
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/SOURCES/*.tar.gz

.PHONY: install-deps
install-deps:
	yum update -y && yum install -y rpm-builder golang-1.15.14-1.amzn2.0.1 pcre-devel glibc-static

.PHONY: check-env
check-env:
ifndef GO_SOURCE_VERSION
$(error environment variable GO_SOURCE_VERSION, e.g. 1.15, is undefined)
endif
