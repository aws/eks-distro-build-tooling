# Disable built-in rules and variables
MAKEFLAGS+=--no-builtin-rules --warn-undefined-variables
SHELL=bash
.SHELLFLAGS:=-eu -o pipefail -c
.SUFFIXES:

BASE_DIRECTORY=$(shell git rev-parse --show-toplevel)
MAKE_ROOT=$(BASE_DIRECTORY)/builder-base

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=builder-base
# This tag is overwritten in the prow job to point to the PR branch commit hash (presubmit)
# or the base branch commit hash (postsubmit)
IMAGE_TAG?=latest

AL_TAG?=2
LATEST?=$(if $(filter $(AL_TAG),2022),$(VARIANT)-latest.al22,$(VARIANT)-latest $(VARIANT)-latest.al2 $(if $(filter standard,$(VARIANT)),latest latest.2,))

IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(VARIANT)-$(IMAGE_TAG)

LATEST_TAGS=$(foreach tag,$(LATEST),$(IMAGE_REPO)/$(IMAGE_NAME):$(tag))
LATEST_IMAGE=$(shell echo $(LATEST_TAGS) | sed "s/ \+/,/g")

BASE_IMAGE_REPO?=public.ecr.aws/eks-distro-build-tooling
BASE_IMAGE_NAME?=eks-distro-minimal-base-kind
BASE_IMAGE?=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME))

# using the minimal-base-builder as the base for the download/gcc stages of
# this build since it doesnt change too often, limiting churn/rebuilds
BUILDER_IMAGE_NAME?=eks-distro-minimal-base
BUILDER_IMAGE?=$(BASE_IMAGE_REPO)/$(BUILDER_IMAGE_NAME)-builder:$(call BASE_TAG_FROM_TAG_FILE,$(BUILDER_IMAGE_NAME))

CURRENT_BUILDER_BASE_TAG=$(or $(and $(wildcard /config/BUILDER_BASE_TAG_FILE),$(shell cat /config/BUILDER_BASE_TAG_FILE)),$(word 1,$(LATEST)))
IMPORT_CACHE_REPOS=public.ecr.aws/eks-distro-build-tooling $(IMAGE_REPO)

BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE),$(LATEST_IMAGE)\",push=true
BUILDKIT_PLATFORMS?=linux/amd64,linux/arm64
FINAL_STAGE_BASE?=full-copy-stage
VARIANT?=standard

NETRC=--secret id=netrc,src=$(HOME)/.netrc

define BASE_TAG_FROM_TAG_FILE
$(shell yq e ".al$(AL_TAG).$(1)" $(MAKE_ROOT)/../EKS_DISTRO_TAG_FILE.yaml)
endef


.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../scripts/buildkit_check.sh

.PHONY: copy-generate-attribution
copy-generate-attribution:
	cp -rf ../generate-attribution ./

.PHONY: remove-generate-attribution
remove-generate-attribution:
	rm -rf ./generate-attribution

.PHONY: local-images
local-images: BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE),$(LATEST_IMAGE)\"
local-images: BUILDKIT_PLATFORMS=linux/amd64
local-images: images-minimal images-standard

.PHONY: images
images: images-minimal images-standard 

images-minimal: FINAL_STAGE_BASE=minimal-copy-stage
images-minimal: VARIANT=minimal

.PHONY: images-%
images-%: buildkit-check
	$(MAKE_ROOT)/../scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(BUILDKIT_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--opt build-arg:GOPROXY=$(GOPROXY) \
		--opt build-arg:FINAL_STAGE_BASE=$(FINAL_STAGE_BASE) \
		--export-cache type=inline \
		$(foreach repo,$(IMPORT_CACHE_REPOS),--import-cache type=registry,ref=$(repo)/builder-base:$(CURRENT_BUILDER_BASE_TAG)) \
		--opt no-cache=final \
		--local dockerfile=./ \
		--local context=. \
		$(if $(wildcard $(HOME)/.netrc),$(NETRC),) \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)
	if [ "$(AL_TAG)" = "2" ] && [ "$(VARIANT)" = "standard" ]; then \
		./update_base_image.sh $(VARIANT)-$(IMAGE_TAG); \
	fi
	

# for local development only
docker: copy-generate-attribution
	docker build \
		-t $(IMAGE) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg TARGETARCH=amd64 \
		--build-arg TARGETOS=linux \
		-f Dockerfile .
	$(MAKE) remove-generate-attribution

.PHONY: build
build: validate-shasums copy-generate-attribution local-images remove-generate-attribution

.PHONY: release
release: validate-shasums copy-generate-attribution images remove-generate-attribution

.PHONY: all
all: release

.PHONY: update-shasums
update-shasums:
	./scripts/update_shasums.sh >/dev/null 2>&1

.PHONY: validate-shasums
validate-shasums: update-shasums
	git diff --exit-code ./checksums
