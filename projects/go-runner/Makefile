RELEASE_BRANCH?=0.18.0
GIT_TAG?=$(shell cat ./$(RELEASE_BRANCH)/GIT_TAG)
MIN_GO_VERSION?=1.25

BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/go-runner

VERSIONS_YAML=$(BASE_DIRECTORY)/eks-distro-base/golang_versions.yaml
GO_CHECKSUMS_DIR=$(BASE_DIRECTORY)/builder-base/checksums
GO_FULL_VERSIONS:=$(shell yq '.golang.versions[]' $(VERSIONS_YAML))
GO_PATCH_VERSION=$(firstword $(subst -, ,$(GO_FULL_VERSION)))
GO_LICENSES_MODULE?=github.com/jaxesn/go-licenses@6800d77c11d0ef8628e7eda908b1d1149383ca48
export GO_TOOLCHAINS_DIR=$(PROJECT_DIRECTORY)/_output/toolchains
export GOTOOLCHAIN=local
GO_TOOLCHAIN_BIN=$(GO_TOOLCHAINS_DIR)/go$(GO_VERSION)/bin

BUILD_INPUTS=$(BASE_DIRECTORY)/scripts/image_build_inputs.sh
BUILD_INPUTS_LABEL:=$(shell $(BUILD_INPUTS) key)
BUILD_INPUT_FILES=$(PROJECT_DIRECTORY)/Makefile $(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/GIT_TAG \
	$(PROJECT_DIRECTORY)/docker/go-runner/Dockerfile $(sort $(wildcard $(PROJECT_DIRECTORY)/build/*.sh)) \
	$(BASE_DIRECTORY)/builder-base/scripts/download_golang.sh \
	$(addprefix $(BASE_DIRECTORY)/scripts/,image_build_inputs.sh common.sh simple_create_binaries.sh gather_licenses.sh)

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=go-runner
PRIVATE_IMAGE_REPO?=

# REPO_FOLDER can't be release since there is a phony release target
# using release-src and overriding component
REPO_FOLDER=release-src
REPO_OWNER=kubernetes
COMPONENT=release
CLONE_URL=https://github.com/$(REPO_OWNER)/$(COMPONENT).git

BINARY_TARGET_FILES=go-runner
GO_MOD_PATHS=images/build/go-runner
FIX_LICENSES_GO_RUNNER_TARGET=$(REPO_FOLDER)/images/build/go-runner/LICENSE

GOOS?=linux
ARCH_LOWER?=amd64
GOLANG_ARCHIVE_PATH=$(GO_VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)/$(GO_BIN_VERSION_WITHOUT_RELEASE).$(GOOS)-$(ARCH_LOWER).tar.gz
ARCHITECTURES="amd64" "arm64"

AL_TAG?=2023
# Strip 20 from 2023 for latest image tags
AL_TAG_LATEST=$(subst 20,,$(AL_TAG))
BASE_IMAGE_REPO?=public.ecr.aws/eks-distro-build-tooling
BASE_IMAGE_NAME?=eks-distro-minimal-base
BASE_IMAGE?=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME))
PUSH_IMAGES?=false
# Manual only: set to true to rebuild and re-push tags even when their build inputs are unchanged
FORCE_BUILD?=false


.PHONY: process-go-versions
process-go-versions:
	@FAILED_VERSIONS=""; \
	for GO_FULL_VERSION in $(GO_FULL_VERSIONS); do \
		GO_PATCH_VERSION=$${GO_FULL_VERSION%-*}; \
		GO_VERSION=$$(echo $$GO_PATCH_VERSION | cut -d. -f1-2); \
		echo "Processing Go $$GO_PATCH_VERSION"; \
		if [[ "$$GO_VERSION" < $(MIN_GO_VERSION) ]]; then \
			echo "Skipping go-runner build with older go version than $(MIN_GO_VERSION)"; \
			continue; \
		fi; \
		IMAGE_TAG=$(GIT_TAG)-go-$$GO_PATCH_VERSION.$(AL_TAG); \
		BUILD_INPUTS_HASH=$$($(BUILD_INPUTS) hash --value $(GIT_TAG) --value $$GO_PATCH_VERSION --value $(BASE_IMAGE) \
			--file $(GO_CHECKSUMS_DIR)/go-go$$GO_VERSION-amd64-checksum \
			$(foreach file,$(BUILD_INPUT_FILES),--file $(file))) || { FAILED_VERSIONS="$$FAILED_VERSIONS $$GO_PATCH_VERSION"; continue; }; \
		PUBLISHED_HASH=$$($(BUILD_INPUTS) label $(IMAGE_REPO)/$(IMAGE_NAME):$$IMAGE_TAG) || { FAILED_VERSIONS="$$FAILED_VERSIONS $$GO_PATCH_VERSION"; continue; }; \
		PRIVATE_IMAGE=$(if $(PRIVATE_IMAGE_REPO),$(PRIVATE_IMAGE_REPO)/$(IMAGE_NAME):$$IMAGE_TAG); \
		PRIVATE_HASH=$$PUBLISHED_HASH; \
		if [ -n "$$PRIVATE_IMAGE" ]; then \
			PRIVATE_HASH=$$($(BUILD_INPUTS) label $$PRIVATE_IMAGE) || { FAILED_VERSIONS="$$FAILED_VERSIONS $$GO_PATCH_VERSION"; continue; }; \
		fi; \
		if [ "$(FORCE_BUILD)" != "true" ] && [ "$(PUSH_IMAGES)" = "true" ] && [ -n "$$BUILD_INPUTS_HASH" ] && \
			[ "$$PUBLISHED_HASH" = "$$BUILD_INPUTS_HASH" ] && [ "$$PRIVATE_HASH" = "$$BUILD_INPUTS_HASH" ]; then \
			echo "$$IMAGE_TAG is already built from these inputs, skipping build.."; \
			continue; \
		fi; \
		echo "$$IMAGE_TAG build inputs changed from '$$PUBLISHED_HASH' to '$$BUILD_INPUTS_HASH'"; \
		LATEST_IMAGE_TAG=$(GIT_TAG)-go-$$GO_VERSION-latest.al$(AL_TAG_LATEST); \
		IMAGES=$(IMAGE_REPO)/$(IMAGE_NAME):$$IMAGE_TAG,$(IMAGE_REPO)/$(IMAGE_NAME):$$LATEST_IMAGE_TAG; \
		$(MAKE) build-multi-arch-images GO_FULL_VERSION=$$GO_FULL_VERSION GO_VERSION=$$GO_VERSION \
			IMAGES=$$IMAGES$${PRIVATE_IMAGE:+,$$PRIVATE_IMAGE} PRIVATE_IMAGE=$$PRIVATE_IMAGE \
			BUILD_INPUTS_HASH=$$BUILD_INPUTS_HASH || FAILED_VERSIONS="$$FAILED_VERSIONS $$GO_PATCH_VERSION"; \
	done; \
	if [ -n "$$FAILED_VERSIONS" ]; then \
		echo "go-runner builds failed for Go$$FAILED_VERSIONS"; \
		exit 1; \
	fi


.PHONY: build-multi-arch-images
build-multi-arch-images:
	@echo "Building $(IMAGES)"
	$(MAKE) download-go GO_FULL_VERSION=$(GO_FULL_VERSION) GO_VERSION=$(GO_VERSION)
	$(MAKE) build-binaries GO_VERSION=$(GO_VERSION)
	$(MAKE) fix-licenses GO_VERSION=$(GO_VERSION)
	$(MAKE) images GO_VERSION=$(GO_VERSION) IMAGES=$(IMAGES) PRIVATE_IMAGE=$(PRIVATE_IMAGE) BUILD_INPUTS_HASH=$(BUILD_INPUTS_HASH)
	$(MAKE) clean-image-build-data


.PHONY: download-go
download-go:
	$(BASE_DIRECTORY)/builder-base/scripts/download_golang.sh $(GO_FULL_VERSION) $(GO_TOOLCHAINS_DIR)/downloads linux/amd64
	rm -rf $(GO_TOOLCHAINS_DIR)/go$(GO_VERSION)
	mkdir -p $(GO_TOOLCHAIN_BIN)
	tar -xzf $(GO_TOOLCHAINS_DIR)/downloads/linux/amd64/go$(GO_PATCH_VERSION).linux-amd64.tar.gz \
		-C $(GO_TOOLCHAINS_DIR)/go$(GO_VERSION) --strip-components=1
	CGO_ENABLED=0 GO111MODULE=on GOBIN=$(GO_TOOLCHAIN_BIN) $(GO_TOOLCHAIN_BIN)/go install $(GO_LICENSES_MODULE)
	$(GO_TOOLCHAIN_BIN)/go version


.PHONY: build-binaries
build-binaries: clone
	echo "Architecture is: $(ARCHITECTURES)"
	@for ARCHITECTURE in $(ARCHITECTURES); do \
		echo "Building go-runner for $${ARCHITECTURE}"; \
		$(BASE_DIRECTORY)/scripts/simple_create_binaries.sh $(PROJECT_DIRECTORY) \
        	$(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/_output/$(GO_VERSION)/bin/$(GOOS)-$${ARCHITECTURE}/go-runner \
        	release-src $(GO_VERSION) "$(GOOS)/$${ARCHITECTURE}" "." "build" "" \
        	"-s -w -buildid= -extldflags -static " 0 "" "images/build/go-runner" "go-runner"; \
	done


.PHONY: fix-licenses
fix-licenses:
#	go-licenses requires a LICENSE file in each folder with the go.mod
	cp $(REPO_FOLDER)/LICENSE $(FIX_LICENSES_GO_RUNNER_TARGET)
	bash $(BASE_DIRECTORY)/scripts/gather_licenses.sh release-src \
		$(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/_output "." images/build/go-runner $(GO_VERSION)
	build/fix_licenses.sh $(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/_output
	build/generate_attribution.sh $(PROJECT_DIRECTORY)/$(RELEASE_BRANCH) $(GO_VERSION)


.PHONY: images
images: buildkit-check
	$(BASE_DIRECTORY)/scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64,linux/arm64 \
		--opt build-arg:GO_VERSION=$(GO_VERSION) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt label:$(BUILD_INPUTS_LABEL)=$(BUILD_INPUTS_HASH) \
		--local dockerfile=$(PROJECT_DIRECTORY)/docker/go-runner \
		--local context=$(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/_output \
		--progress plain \
		--output type=image,oci-mediatypes=true,\"name=$(IMAGES)\",push=$(PUSH_IMAGES)
	if [ "$(PUSH_IMAGES)" = "true" ]; then $(BASE_DIRECTORY)/scripts/tag_image_children.sh $(IMAGES); fi
	if [ "$(PUSH_IMAGES)" = "true" ] && [ -n "$(PRIVATE_IMAGE)" ]; then \
		$(BASE_DIRECTORY)/scripts/tag_image_children.sh $(PRIVATE_IMAGE) || echo "WARNING: failed to tag child images for $(PRIVATE_IMAGE)"; \
	fi


.PHONY: clean-image-build-data
clean-image-build-data:
	rm -rf $(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/_output


.PHONY: clone
clone:
	@if [ ! -d "$(REPO_FOLDER)" ]; then \
		git clone $(CLONE_URL) $(REPO_FOLDER); \
	else \
		echo "$(REPO_FOLDER) already cloned, skipping..."; \
	fi
	cd $(REPO_FOLDER) && git checkout $(GIT_TAG)


.PHONY: buildkit-check
buildkit-check:
	$(BASE_DIRECTORY)/scripts/buildkit_check.sh


.PHONY: release
release: process-go-versions clean


.PHONY: build
build: export PUSH_IMAGES=false
build: process-go-versions clean


.PHONY: clean
clean:
	rm -rf $(REPO_FOLDER) $(GO_TOOLCHAINS_DIR)


define BASE_TAG_FROM_TAG_FILE
$(shell yq e ".al$(AL_TAG).\"$(1)\"" $(BASE_DIRECTORY)/EKS_DISTRO_TAG_FILE.yaml)
endef
