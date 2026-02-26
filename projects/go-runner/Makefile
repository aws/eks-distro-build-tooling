RELEASE_BRANCH?=0.18.0
GIT_TAG?=$(shell cat ./$(RELEASE_BRANCH)/GIT_TAG)
MIN_GO_VERSION?=1.24

BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/projects/go-runner

# Get available go versions on the builder image
GO_VERSIONS := $(wildcard /go/go*)
AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=go-runner

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

AL_TAG?=2
# Remove 20 from 2023 for latest image tags
AL_TAG_LATEST=$(subst 20,,$(AL_TAG))
BASE_IMAGE_REPO?=public.ecr.aws/eks-distro-build-tooling
BASE_IMAGE_NAME?=eks-distro-minimal-base
BASE_IMAGE?=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME))
PUSH_IMAGES?=false


.PHONY: process-go-versions
process-go-versions:
	@for GOROOT in $(GO_VERSIONS); do \
		echo "Processing for $$GOROOT"; \
		GO_VERSION=$${GOROOT/\/go\/go/}; \
		if [[ "$$GO_VERSION" < $(MIN_GO_VERSION) ]]; then \
			echo "Skipping go-runner build with older go version than $(MIN_GO_VERSION)"; \
			continue; \
		fi; \
		GO_PATCH_VERSION=`$$GOROOT/bin/go version | awk '{print $$3}' | sed 's/go//'` ; \
		IMAGE_TAG=$(GIT_TAG)-go-$$GO_PATCH_VERSION.$(AL_TAG); \
		echo "Checking if image already pushed: $(IMAGE_REPO)/$(IMAGE_NAME):$$IMAGE_TAG"; \
		if docker manifest inspect $(IMAGE_REPO)/$(IMAGE_NAME):$$IMAGE_TAG > /dev/null 2>&1; then \
			echo "$$IMAGE_TAG exists in repository, skipping build.."; \
		else \
			echo "$$IMAGE_TAG doesn't exist in repository"; \
			LATEST_IMAGE_TAG=$(GIT_TAG)-go-$$GO_VERSION-latest.al$(AL_TAG_LATEST); \
			IMAGES=$(IMAGE_REPO)/$(IMAGE_NAME):$$IMAGE_TAG,$(IMAGE_REPO)/$(IMAGE_NAME):$$LATEST_IMAGE_TAG; \
			$(MAKE) build-multi-arch-images GO_VERSION=$$GO_VERSION IMAGES=$$IMAGES; \
		fi; \
	done


.PHONY: build-multi-arch-images
build-multi-arch-images:
	@echo "Building $(IMAGES)"
	$(MAKE) build-binaries GO_VERSION=$(GO_VERSION)
	$(MAKE) fix-licenses GO_VERSION=$(GO_VERSION)
	$(MAKE) images GO_VERSION=$(GO_VERSION) IMAGES=$(IMAGES)
	$(MAKE) clean-image-build-data


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
		--local dockerfile=$(PROJECT_DIRECTORY)/docker/go-runner \
		--local context=$(PROJECT_DIRECTORY)/$(RELEASE_BRANCH)/_output \
		--progress plain \
		--output type=image,oci-mediatypes=true,\"name=$(IMAGES)\",push=$(PUSH_IMAGES)


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


.PHONY: clean
clean:
	rm -rf $(REPO_FOLDER)


define BASE_TAG_FROM_TAG_FILE
$(shell yq e ".al$(AL_TAG).\"$(1)\"" $(BASE_DIRECTORY)/EKS_DISTRO_TAG_FILE.yaml)
endef
