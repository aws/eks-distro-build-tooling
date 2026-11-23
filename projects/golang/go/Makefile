BUILD_ID=$(shell cat ./$(GO_SOURCE_VERSION)/RELEASE 2>/dev/null)
IMAGE_BUILD_ID=$(shell cat ./docker/debianBase/RELEASE)

BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)

PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/golang/go
VERSION_DIRECTORY:=$(PROJECT_DIRECTORY)/$(GO_SOURCE_VERSION)

GOOS?=linux
ARCHITECTURE?=AMD64
ARCH_LOWER=$(call TO_LOWER,$(ARCHITECTURE))

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)

# This build is specifically focused on a debian base image for use with EKS build systems
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=golang-debian
PRIVATE_IMAGE_REPO?=
COMMA=,
GOLANG_VERSIONS_YAML=$(BASE_DIRECTORY)/eks-distro-base/golang_versions.yaml
GO_BIN_VERSION_WITH_RELEASE:=$(shell yq '.golang.versions["GOLANG_$(GO_SOURCE_VERSION)_FULL_VERSION"] // ""' $(GOLANG_VERSIONS_YAML))
GO_BIN_VERSION_WITHOUT_RELEASE=go$(shell [[ $(GO_BIN_VERSION_WITH_RELEASE) =~ [0-9]+.[0-9]+.[0-9]+ ]] && echo $${BASH_REMATCH[0]})

GOLANG_VARIANTS:=$(shell yq '.golang.variants[]' $(GOLANG_VERSIONS_YAML))
RELEASED_VERSIONS_FILE=$(PROJECT_DIRECTORY)/_output/released-versions
BUILD_INPUTS=$(BASE_DIRECTORY)/scripts/image_build_inputs.sh
BUILD_INPUTS_LABEL:=$(shell $(BUILD_INPUTS) key)
BUILD_INPUT_FILES=$(PROJECT_DIRECTORY)/Makefile $(PROJECT_DIRECTORY)/docker/debianBase/Dockerfile \
	$(PROJECT_DIRECTORY)/scripts/get_upstream_golang.sh $(BUILD_INPUTS)
UPSTREAM_BINS_BUILD_ID=$(or $(BUILD_ID),1)
UPSTREAM_BINS_IMAGE_TAG=$(GO_BIN_VERSION_WITHOUT_RELEASE)-$(UPSTREAM_BINS_BUILD_ID)-$(IMAGE_BUILD_ID)
UPSTREAM_BINS_IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(UPSTREAM_BINS_IMAGE_TAG)
UPSTREAM_BINS_PRIVATE_IMAGE=$(if $(PRIVATE_IMAGE_REPO),$(PRIVATE_IMAGE_REPO)/$(IMAGE_NAME):$(UPSTREAM_BINS_IMAGE_TAG))
NOTIFY_SKIPPED?=false

PUSH_IMAGES?=true
BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE)\",push=$(PUSH_IMAGES)

TO_LOWER=$(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst \
	F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst \
	M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst \
	T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$(subst _,-,$(1))))))))))))))))))))))))))))

.PHONY: prod-release-images-upstream-bins
prod-release-images-upstream-bins: export AWS_PROFILE=ecr-public-push
prod-release-images-upstream-bins: images-upstream-bins

.PHONY: prod-release-images-upstream-bins-all
prod-release-images-upstream-bins-all:
	mkdir -p $(dir $(RELEASED_VERSIONS_FILE))
	: > $(RELEASED_VERSIONS_FILE)
	FAILED_VERSIONS=""; \
	for version in $(GOLANG_VARIANTS); do \
		$(MAKE) release-images-upstream-bins-variant GO_SOURCE_VERSION=$$version || FAILED_VERSIONS="$$FAILED_VERSIONS $$version"; \
	done; \
	if [ -n "$$FAILED_VERSIONS" ]; then \
		echo "golang-debian builds failed for Go$$FAILED_VERSIONS"; \
		exit 1; \
	fi

.PHONY: release-images-upstream-bins-variant
release-images-upstream-bins-variant:
	@if [ "$(GO_BIN_VERSION_WITHOUT_RELEASE)" = "go" ]; then \
		echo "Missing GOLANG_$(GO_SOURCE_VERSION)_FULL_VERSION in eks-distro-base/golang_versions.yaml"; \
		exit 1; \
	fi
	BUILD_INPUTS_HASH=$$($(BUILD_INPUTS) hash --value $(GO_BIN_VERSION_WITHOUT_RELEASE) --value $(UPSTREAM_BINS_BUILD_ID) \
		--value $(IMAGE_BUILD_ID) \
		--file $(BASE_DIRECTORY)/builder-base/checksums/go-go$(GO_SOURCE_VERSION)-amd64-checksum \
		$(foreach file,$(BUILD_INPUT_FILES),--file $(file))) || exit 1; \
	PUBLISHED_HASH=$$($(BUILD_INPUTS) label $(UPSTREAM_BINS_IMAGE)) || exit 1; \
	PRIVATE_HASH=$$PUBLISHED_HASH; \
	if [ -n "$(UPSTREAM_BINS_PRIVATE_IMAGE)" ]; then PRIVATE_HASH=$$($(BUILD_INPUTS) label $(UPSTREAM_BINS_PRIVATE_IMAGE)) || exit 1; fi; \
	if [ "$(PUSH_IMAGES)" = "true" ] && [ -n "$$BUILD_INPUTS_HASH" ] && \
		[ "$$PUBLISHED_HASH" = "$$BUILD_INPUTS_HASH" ] && [ "$$PRIVATE_HASH" = "$$BUILD_INPUTS_HASH" ]; then \
		echo "$(UPSTREAM_BINS_IMAGE) is already built from these inputs, skipping build.."; \
		if [ "$(NOTIFY_SKIPPED)" = "true" ]; then \
			echo "$(GO_SOURCE_VERSION) $(GO_BIN_VERSION_WITHOUT_RELEASE) $(UPSTREAM_BINS_BUILD_ID) $(IMAGE_BUILD_ID)" >> $(RELEASED_VERSIONS_FILE); \
		fi; \
		exit 0; \
	fi; \
	echo "$(UPSTREAM_BINS_IMAGE) build inputs changed from '$$PUBLISHED_HASH' to '$$BUILD_INPUTS_HASH'"; \
	$(MAKE) prod-release-images-upstream-bins GO_SOURCE_VERSION=$(GO_SOURCE_VERSION) BUILD_INPUTS_HASH=$$BUILD_INPUTS_HASH || exit 1; \
	if [ "$(PUSH_IMAGES)" = "true" ]; then \
		echo "$(GO_SOURCE_VERSION) $(GO_BIN_VERSION_WITHOUT_RELEASE) $(UPSTREAM_BINS_BUILD_ID) $(IMAGE_BUILD_ID)" >> $(RELEASED_VERSIONS_FILE); \
	fi

.PHONY: fetch-golang-upstream-bins
fetch-golang-upstream-bins:
	$(PROJECT_DIRECTORY)/scripts/get_upstream_golang.sh $(VERSION_DIRECTORY)/archives/ $(GO_BIN_VERSION_WITHOUT_RELEASE)

.PHONY: local-images-upstream-bins
local-images-upstream-bins: PUSH_IMAGES=false
local-images-upstream-bins: export BUILDKIT_HOST=docker-container://buildkitd
local-images-upstream-bins: images-upstream-bins

.PHONY: images-upstream-bins
images-upstream-bins: IMAGE_TAG=$(UPSTREAM_BINS_IMAGE_TAG)
images-upstream-bins: LATEST_IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(GO_BIN_VERSION_WITHOUT_RELEASE)
images-upstream-bins: IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG),$(LATEST_IMAGE)$(if $(UPSTREAM_BINS_PRIVATE_IMAGE),$(COMMA)$(UPSTREAM_BINS_PRIVATE_IMAGE))
images-upstream-bins: fetch-golang-upstream-bins buildkit-check
images-upstream-bins:
	$(BASE_DIRECTORY)/scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(GOOS)/$(ARCH_LOWER) \
		--opt build-arg:GOLANG_ARCHIVE_PATH=$(GOOS)/$(ARCH_LOWER)/$(GO_BIN_VERSION_WITHOUT_RELEASE).$(GOOS)-$(ARCH_LOWER).tar.gz \
		--opt label:$(BUILD_INPUTS_LABEL)=$(BUILD_INPUTS_HASH) \
		--local dockerfile=$(PROJECT_DIRECTORY)/docker/debianBase \
		--local context=$(VERSION_DIRECTORY)/archives \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)

.PHONY: clean
clean:
	rm -rf $(VERSION_DIRECTORY)/archives $(PROJECT_DIRECTORY)/_output

.PHONY: buildkit-check
buildkit-check:
	$(BASE_DIRECTORY)/scripts/buildkit_check.sh
