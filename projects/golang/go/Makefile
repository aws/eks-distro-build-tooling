GIT_TAG?=$(shell cat ./$(GO_SOURCE_VERSION)/GIT_TAG)
BUILD_ID=$(shell cat ./$(GO_SOURCE_VERSION)/RELEASE)
IMAGE_BUILD_ID=$(shell cat ./docker/debianBase/RELEASE)

export PATH:=/go/go$(GO_SOURCE_VERSION)/bin:$(PATH)

BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)

PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/golang/go
VERSION_DIRECTORY:=$(PROJECT_DIRECTORY)/$(GO_SOURCE_VERSION)
CLONED_REPO_DIRECTORY:=$(VERSION_DIRECTORY)/go

GO_REPO_URL?="https://github.com/golang/go.git"

GITHUB_EMAIL?="prow@amazonaws.com"
GITHUB_USER?="Prow Bot"

GOOS?=linux

# the values used by rpmbuild for indicating architecture are different than that of our other systems.
# rather than use 'x86_64' throughout, we just make sure to set the RPM arch to the right value here.
ARCHITECTURE?=AMD64
RPM_ARCH?=x86_64
ifeq ($(ARCHITECTURE), ARM64)
	RPM_ARCH=aarch64
endif
ARCH_LOWER=$(call TO_LOWER,$(ARCHITECTURE))

ARCH_RPM_OUT_PATH?=golang-$(GIT_TAG)/releases/$(BUILD_ID)/$(RPM_ARCH)/RPMS/$(RPM_ARCH)
NOARCH_RPM_OUT_PATH?=golang-$(GIT_TAG)/releases/$(BUILD_ID)/$(RPM_ARCH)/RPMS/noarch
ARCHIVES_OUT_PATH?=golang-$(GIT_TAG)/releases/$(BUILD_ID)/archives

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)

# This build is specifically focused on a debian base image for use with EKS build systems
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=golang-debian
IMAGE_TAG?=$(GIT_TAG)-$(BUILD_ID)-$(IMAGE_BUILD_ID)
LATEST_IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(GIT_TAG)
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG),$(LATEST_IMAGE)
# Variables used in the using upstream binarys in the golang-debian image
BUILDER_BASE_VERSIONS_YAML=$(BASE_DIRECTORY)/builder-base/versions.yaml
BUILDER_BASE_GO_VERSION=$(shell grep -E "^GOLANG_VERSION_$(subst .,,$(GO_SOURCE_VERSION))" $(BUILDER_BASE_VERSIONS_YAML))
GO_BIN_VERSION_WITH_RELEASE=$(subst GOLANG_VERSION_$(subst .,,$(GO_SOURCE_VERSION)): ,,$(BUILDER_BASE_GO_VERSION))
GO_BIN_VERSION_WITHOUT_RELEASE=go$(shell [[ $(GO_BIN_VERSION_WITH_RELEASE) =~ [0-9]+.[0-9]+.[0-9]+ ]] && echo $${BASH_REMATCH[0]})

PUSH_IMAGES?=true
BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE)\",push=$(PUSH_IMAGES)

TO_LOWER=$(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst \
	F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst \
	M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst \
	T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$(subst _,-,$(1))))))))))))))))))))))))))))

RELEASE_TARGETS = golang-build sync-artifacts-to-s3
# We only build the Debian base image for AAMD64. Skip for other architectures.
ifeq ($(ARCHITECTURE), AMD64)
    RELEASE_TARGETS += images
endif

# This allows us to skip the image-build in the pre-prod build target if we want to
# This is useful if you only want to test the RPM build and not worry about having buildkit set up on the host
BUILD_PREPROD_IMAGES?=true

BUILD_TARGETS = golang-build sync-artifacts-to-s3-dry-run
ifeq ($(BUILD_PREPROD_IMAGES), true)
	BUILD_TARGETS += clean
	BUILD_TARGETS += local-images
endif

.PHONY: golang-build
golang-build: check-env setup-rpm-tree fetch-golang-source-archive copy-sources-to-rpmbuild-tree copy-patches-to-rpmbuild-tree build-golang-rpm generate-golang-archive test generate-golang-checksum

.PHONY: build
build: $(BUILD_TARGETS)

.PHONY: release
release: $(RELEASE_TARGETS)

.PHONY: prod-release
prod-release: golang-build sync-artifacts-to-s3

.PHONY: prod-release-images
prod-release-images: export AWS_PROFILE=ecr-public-push
prod-release-images: fetch-eks-go-archive images

.PHONY: fetch-eks-go-archive
fetch-eks-go-archive: download-go-archive validate-go-archive-checksum

.PHONY: download-go-archive
download-go-archive:
	curl -L -o $(VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz https://distro.eks.amazonaws.com/golang-$(GIT_TAG)/releases/$(BUILD_ID)/archives/$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz --create-dirs
	curl -L -o $(VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz.sha256 https://distro.eks.amazonaws.com/golang-$(GIT_TAG)/releases/$(BUILD_ID)/archives/$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz.sha256 --create-dirs

.PHONY: validate-go-archive-checksum
validate-go-archive-checksum:
	cd $(VERSION_DIRECTORY)/archives ; \

	for fileDir in $$(find . -type f -name '*.tar.gz'); do \
		if [[ $$(sha256sum $${fileDir} | cut -d ' ' -f1) != $$(cut -d ' ' -f1 "$${fileDir}.sha256") ]] ; then \
			echo "Checksum doesn't match!" ; \
			exit 1 ; \
		fi ; \
	done

.PHONY: prod-release-images-upstream-bins
prod-release-images-upstream-bins: export AWS_PROFILE=ecr-public-push
prod-release-images-upstream-bins: images-upstream-bins

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
	rpmbuild -v -ba $(VERSION_DIRECTORY)/rpmbuild/SPECS/golang.spec --define "_rpmdir $(VERSION_DIRECTORY)/rpmbuild" --define "_buildid $(BUILD_ID)"

.PHONY: local-images
local-images: PUSH_IMAGES=false
local-images: images

.PHONY: images
images: buildkit-check
images:
	$(BASE_DIRECTORY)/scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(GOOS)/$(ARCH_LOWER) \
		--opt build-arg:GOLANG_ARCHIVE_PATH=$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz \
		--local dockerfile=$(PROJECT_DIRECTORY)/docker/debianBase \
		--local context=$(VERSION_DIRECTORY)/archives \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)

.PHONY: fetch-golang-upstream-bins
fetch-golang-upstream-bins:
	$(PROJECT_DIRECTORY)/scripts/get_upstream_golang.sh $(VERSION_DIRECTORY)/archives/ $(GO_BIN_VERSION_WITHOUT_RELEASE)

.PHONY: local-images-upstream-bins
local-images-upstream-bins: PUSH_IMAGES=false
local-images-upstream-bins: export BUILDKIT_HOST=docker-container://buildkitd
local-images-upstream-bins: images-upstream-bins

.PHONY: images-upstream-bins
images-upstream-bins: IMAGE_TAG=$(GO_BIN_VERSION_WITHOUT_RELEASE)-$(BUILD_ID)-$(IMAGE_BUILD_ID)
images-upstream-bins: LATEST_IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(GO_BIN_VERSION_WITHOUT_RELEASE)
images-upstream-bins: IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG),$(LATEST_IMAGE)
images-upstream-bins: fetch-golang-upstream-bins buildkit-check
images-upstream-bins:
	$(BASE_DIRECTORY)/scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(GOOS)/$(ARCH_LOWER) \
		--opt build-arg:GOLANG_ARCHIVE_PATH=$(GOOS)/$(ARCH_LOWER)/$(GO_BIN_VERSION_WITHOUT_RELEASE).$(GOOS)-$(ARCH_LOWER).tar.gz \
		--local dockerfile=$(PROJECT_DIRECTORY)/docker/debianBase \
		--local context=$(VERSION_DIRECTORY)/archives \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)

.PHONY: generate-golang-archive
generate-golang-archive: extract-golang-rpm tar-golang-sources

.PHONY: extract-golang-rpm
extract-golang-rpm:
	mkdir /tmp/go-extracted
	for rpm in $(VERSION_DIRECTORY)/rpmbuild/$(RPM_ARCH)/golang-*.rpm; do \
		cd /tmp/go-extracted && rpm2cpio $$rpm | cpio -idm ; \
	done

	for rpm in $(VERSION_DIRECTORY)/rpmbuild/noarch/golang-*.rpm; do \
		cd /tmp/go-extracted && rpm2cpio $$rpm | cpio -idm ; \
	done

.PHONY: tar-golang-sources
tar-golang-sources:
	mkdir -p $(VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)
	cd /tmp/go-extracted/usr/lib/golang && rm -rf ./pkg/obj && tar czf $(VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz .

.PHONY: generate-golang-checksum
generate-golang-checksum: generate-rpm-checksum generate-archive-checksum

.PHONY: generate-rpm-checksum
generate-rpm-checksum: generate-rpm-arch-checksum generate-rpm-nonarch-checksum

.PHONY: generate-rpm-arch-checksum
generate-rpm-arch-checksum:
	cd $(VERSION_DIRECTORY)/rpmbuild/$(RPM_ARCH) ; \
	pwd && ls -al ; \
	for fileDir in $$(find . -type f -name 'golang-*.rpm'); do \
		echo $${fileDir} ; \
		$$(echo sha256sum $${fileDir}) ; \
		sha256sum $${fileDir} > "$${fileDir}.sha256" ; \
		cat "$${fileDir}.sha256" ; \
	done

.PHONY: generate-rpm-nonarch-checksum
generate-rpm-nonarch-checksum:
	cd $(VERSION_DIRECTORY)/rpmbuild/noarch ; \
	pwd && ls -al ; \
	for fileDir in $$(find . -type f -name 'golang-*.rpm'); do \
		echo $${fileDir} ; \
		$$(echo sha256sum $${fileDir}) ; \
		sha256sum $${fileDir} > "$${fileDir}.sha256" ; \
		cat "$${fileDir}.sha256" ; \
	done

.PHONY: generate-archive-checksum
generate-archive-checksum:
	cd $(VERSION_DIRECTORY)/archives ; \
	pwd && ls -al ; \
	for fileDir in $$(find . -type f -name '*.tar.gz'); do \
		echo $${fileDir} ; \
		$$(echo sha256sum $${fileDir}) ; \
		sha256sum $${fileDir} > "$${fileDir}.sha256" ; \
		cat "$${fileDir}.sha256" ; \
	done

.PHONY: sync-artifacts-to-s3-dry-run
sync-artifacts-to-s3-dry-run: check-env-release
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/rpmbuild/$(RPM_ARCH) $(ARCH_RPM_OUT_PATH) true true
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/rpmbuild/noarch $(NOARCH_RPM_OUT_PATH) true true
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/archives $(ARCHIVES_OUT_PATH) true true

.PHONY: sync-artifacts-to-s3
sync-artifacts-to-s3: check-env-release
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/rpmbuild/$(RPM_ARCH) $(ARCH_RPM_OUT_PATH) true false
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/rpmbuild/noarch $(NOARCH_RPM_OUT_PATH) true false
	source $(BASE_DIRECTORY)/scripts/sync_to_s3.sh && sync_artifacts_to_s3 $(ARTIFACTS_BUCKET) $(VERSION_DIRECTORY)/archives $(ARCHIVES_OUT_PATH) true false

.PHONY: setup-prod-release-s3-credentials
setup-prod-release-s3-credentials:
	$(PROJECT_DIRECTORY)/scripts/release_s3_configuration.sh

.PHONY: test
test: test-windows test-darwin test-linux

.PHONY: test-windows
test-windows: test-platform-windows-amd64 test-platform-windows-386

.PHONY: test-darwin
test-darwin: test-platform-darwin-amd64 test-platform-darwin-arm64

.PHONY: test-linux
test-linux: test-platform-linux-s390x test-platform-linux-ppc64le test-platform-linux-arm test-platform-linux-arm64 test-platform-linux-386

.PHONY: test-platform-%
test-platform-%: platform_tuple = $(subst -, ,$(*))
test-platform-%: goos = $(word 1, $(platform_tuple))
test-platform-%: goarch = $(word 2, $(platform_tuple))
test-platform-%: goroot = $(shell /tmp/go-extracted/usr/lib/golang/bin/go env GOROOT)
test-platform-%:
	echo installing standard library for GOOS=$(goos) GOARCH=$(goarch)
	GOOS=$(goos) GOARCH=$(goarch) /tmp/go-extracted/usr/lib/golang/bin/go install std
	rm -rf $(goroot)/pkg/$(goos)_$(goarch) # clean up the std lib installs as we go to avoid space issues

.PHONY: clean
clean:
	rm -rf $(CLONED_REPO_DIRECTORY)
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/noarch
	rm -rf $(VERSION_DIRECTORY)/rpmbuild/x86_64
	rm -rf $(HOME)/rpmbuild
	rm -rf /tmp/go-extracted

.PHONY: install-deps
install-deps:
	yum install -y yum-plugin-ovl && yum install -y rpmdevtools go-srpm-macros rpm-build glibc-static pcre2-devel

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

.PHONY: buildkit-check
buildkit-check:
	$(BASE_DIRECTORY)/scripts/buildkit_check.sh


