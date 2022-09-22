BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
GIT_TAG?=$(shell cat ./$(GO_SOURCE_VERSION)/GIT_TAG)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/golang/go/$(GO_SOURCE_VERSION)
CLONED_REPO_DIRECTORY:=$(PROJECT_DIRECTORY)/go

GO_VERSION_TAG?=$(shell cat $(PROJECT_DIRECTORY)/GIT_TAG)
GO_REPO_URL?="https://github.com/golang/go.git"

GITHUB_EMAIL?="prow@amazonaws.com"
GITHUB_USER?="Prow Bot"

.PHONY: build
build: check-env clone-golang patch-golang build-golang

.PHONY: clone-golang
clone-golang:
	git -C $(PROJECT_DIRECTORY) clone $(GO_REPO_URL)

.PHONY: patch-golang
patch-golang:
	git -C $(CLONED_REPO_DIRECTORY) config user.email $(GITHUB_EMAIL)
	git -C $(CLONED_REPO_DIRECTORY) config user.name $(GITHUB_USER)
	git -C $(CLONED_REPO_DIRECTORY) checkout $(GO_VERSION_TAG)
	git -C $(CLONED_REPO_DIRECTORY) am --committer-date-is-author-date $(PROJECT_DIRECTORY)/patches/*

.PHONY: build-golang
build-golang:
	(cd $(CLONED_REPO_DIRECTORY)/src && ./all.bash)

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)

.PHONY: check-env
check-env:
ifndef GO_SOURCE_VERSION
$(error environment variable GO_SOURCE_VERSION, e.g. 1.15, is undefined)
endif