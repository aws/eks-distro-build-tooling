SHELL := /bin/bash

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
BASE_IMAGE_REPO?=$(IMAGE_REPO)
IMAGE_NAME?=eks-distro-$(VARIANT)
IMAGE_TAG?=$(shell date "+%F-%s")
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

# base and minimal-base use al2 as the base image
AL_TAG?=2
BASE_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:$(AL_TAG)
BUILDER_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:$(AL_TAG)

LATEST?=latest

ifeq (2022,$(AL_TAG))
	LATEST:=$(LATEST).2022
else
	# tag al2 build with latest.2 and latest for backward compat
	LATEST:=$(LATEST) $(LATEST).2
endif

LATEST_TAGS=$(foreach tag,$(LATEST),$(IMAGE_REPO)/$(IMAGE_NAME):$(tag))
LATEST_IMAGE=$(shell echo $(LATEST_TAGS) | sed "s/ \+/,/g")

VARIANT?=base
IMAGE_TARGET?=base
DOCKERFILE?=Dockerfile.$(VARIANT)
PLATFORMS?=linux/amd64,linux/arm64

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

MINIMAL_VARIANTS=base base-nonroot base-glibc base-iptables base-csi base-git base-docker-client base-nginx base-haproxy base-kind
IMAGE_TARGETS=base-images $(addprefix minimal-images-, $(MINIMAL_VARIANTS))
UPDATE_TARGETS=base-update $(addprefix minimal-update-, $(MINIMAL_VARIANTS))
CREATE_PR_TARGETS=base-create-pr $(addprefix minimal-create-pr-, $(MINIMAL_VARIANTS))

BASE_IMAGE_NAME?=eks-distro-base
BUILDER_IMAGE_NAME?=eks-distro-base
BASE_IMAGE_TAG?=$(IMAGE_TAG)

BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE),$(LATEST_IMAGE)\",push=true

ifeq ($(VARIANT),$(filter $(VARIANT), minimal-base-nonroot minimal-base-glibc))
	BASE_IMAGE_NAME=eks-distro-minimal-base
	BUILDER_IMAGE_NAME=eks-distro-minimal-base-builder
	BASE_IMAGE_TAG=$(call BASE_TAG_FROM_TAG_FILE,eks-distro-minimal-base)
else ifeq ($(VARIANT),$(filter $(VARIANT), minimal-base-iptables minimal-base-csi minimal-base-git minimal-base-docker-client minimal-base-nginx minimal-base-haproxy))
	BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
	BUILDER_IMAGE_NAME=eks-distro-minimal-base-glibc-builder
	BASE_IMAGE_TAG=$(call BASE_TAG_FROM_TAG_FILE,eks-distro-minimal-base-glibc)
else ifeq ($(VARIANT),$(filter $(VARIANT), minimal-base-kind))
	BASE_IMAGE_NAME=eks-distro-minimal-base-iptables
	BUILDER_IMAGE_NAME=eks-distro-minimal-base-iptables-builder
	BASE_IMAGE_TAG=$(call BASE_TAG_FROM_TAG_FILE,eks-distro-minimal-base-iptables)
else ifeq ($(VARIANT), minimal-base)
	BASE_IMAGE=scratch
endif

# if the image was built, either via this being a pre/post submit job
# or a periodic which pushed and created the -pushed file
# use the current IMAGE_TAG as the tag
# if not, use the image tag that will be pulled from the TAG_FILE
# in the previous if/else block
ifneq ($(VARIANT),$(filter $(VARIANT), base minimal-base))
	BASE_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(BASE_IMAGE_TAG)
	BUILDER_IMAGE=$(BASE_IMAGE_REPO)/$(BUILDER_IMAGE_NAME):$(BASE_IMAGE_TAG)
	ifneq ($(and $(JOB_TYPE), $(JOB_TYPE),$(filter $(JOB_TYPE), presubmit postsubmit)),)
		BASE_IMAGE_TAG=$(IMAGE_TAG)
	 else ifeq ($(shell cat $(MAKE_ROOT)/$(BASE_IMAGE_NAME)-pushed), true)		
	 	BASE_IMAGE_TAG=$(IMAGE_TAG)
	endif
endif

define BASE_TAG_FROM_TAG_FILE
$(shell yq e ".al$(AL_TAG).$(1)" $(MAKE_ROOT)/../EKS_DISTRO_TAG_FILE.yaml)
endef

## --------------------------------------
## Help
## --------------------------------------
##@ Helpers
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../scripts/buildkit_check.sh


# There is no local images target since the minimal images build on each other we need a registry to push to
# in prow we run a docker registry as a sidecar
# see the README.md on how to run these targets locally
.PHONY: images-%
images-%: buildkit-check
	if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./check_update.sh $(IMAGE_NAME) $(AL_TAG); \
	fi
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt filename=$(DOCKERFILE) \
		--opt platform=$(PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--progress plain \
		--local dockerfile=./ \
		--local context=. \
		--opt target=$(IMAGE_TARGET) \
		--output $(BUILDKIT_OUTPUT)

# Standard distro-base image build
.PHONY: base-%
base-%:
	$(MAKE) $*-base PLATFORMS=$(PLATFORMS)

.PHONY: minimal-images-%
minimal-images-%:
	$(MAKE) images-minimal-$* VARIANT=minimal-$* IMAGE_TARGET=$* PLATFORMS=$(PLATFORMS)
	$(MAKE) images-minimal-$*-builder VARIANT=minimal-$* IMAGE_TARGET=$*-builder PLATFORMS=$(PLATFORMS) IMAGE_NAME=eks-distro-minimal-$*-builder 
	$(MAKE) export-minimal-images-$* VARIANT=minimal-$* IMAGE_TARGET=$* PLATFORMS=$(PLATFORMS)

.PHONY: export-minimal-images-%
export-minimal-images-%:
	if [ "$(JOB_TYPE)" = "postsubmit" ] || \
		[ "$(shell cat $(MAKE_ROOT)/eks-distro-minimal-$*-pushed)" = "true" ]; then \
		$(MAKE) images-minimal-$* VARIANT=minimal-$* IMAGE_TARGET=$*-export PLATFORMS=$(PLATFORMS) BUILDKIT_OUTPUT="type=local,dest=$(MAKE_ROOT)/../eks-distro-base-minimal-packages/$(AL_TAG)"; \
	fi


# for local development only
.PHONY: minimal-base-test
minimal-base-test: 
	./tests/run_tests.sh $(IMAGE_REPO) $(IMAGE_TAG)

.PHONY: ecr
ecr:
	aws ecr create-repository \
		--repository-name $(IMAGE_NAME) \
		--image-tag-mutability IMMUTABLE \
		--image-scanning-configuration  scanOnPush=true || true

.PHONY: build
build: PLATFORMS=linux/amd64
build: $(IMAGE_TARGETS)

.PHONY: release
release: $(IMAGE_TARGETS)

.PHONY: update-%
update-%: UPDATE_TARGET?=images-$*
update-%:
	echo "false" > $(MAKE_ROOT)/$(IMAGE_NAME)-pushed
	$(eval RETURN_MESSAGE="$(shell ./check_update.sh $(IMAGE_NAME) $(AL_TAG) )")
	if [ $(RETURN_MESSAGE) = "Updates required" ]; then \
		$(MAKE) $(UPDATE_TARGET); \
		echo "true" > $(MAKE_ROOT)/$(IMAGE_NAME)-pushed; \
	elif [ $(RETURN_MESSAGE) = "Error" ]; then \
		exit 1; \
	fi

.PHONY: base-update
base-update:
	$(MAKE) update-base

.PHONY: minimal-update-%
minimal-update-%:
	$(MAKE) update-$* UPDATE_TARGET=minimal-images-$* VARIANT=minimal-$*

# Update tag files in and create PR against eks-distro-build-tooling and eks-distro repos
.PHONY: create-pr-%
create-pr-%: ensure-repo-owner
	if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./update_base_image.sh $(IMAGE_TAG) $(IMAGE_NAME) $(AL_TAG); \
	elif [ "$(shell cat $(MAKE_ROOT)/$(IMAGE_NAME)-pushed)" = "true" ]; then \
		./update_base_image.sh $(IMAGE_TAG) $(IMAGE_NAME) $(AL_TAG); \
	fi

.PHONY: base-create-pr
base-create-pr:
	$(MAKE) create-pr-base

.PHONY: minimal-create-pr-%
minimal-create-pr-%:
	$(MAKE) create-pr-$* IMAGE_NAME=eks-distro-minimal-$*

.PHONY: ensure-repo-owner
ensure-repo-owner:
ifndef REPO_OWNER
	$(error No org information was provided, please set and export REPO_OWNER environment variable. \
	This is used to raise a pull request against your org after updating tags in the respective files.)
endif

.PHONY: create-pr
create-pr: $(CREATE_PR_TARGETS)
	$(MAKE_ROOT)/../pr-scripts/create_pr.sh eks-distro-build-tooling 'EKS_DISTRO*_TAG_FILE*'

.PHONY: update
update: buildkit-check open-pr-check $(UPDATE_TARGETS)

.PHONY: update-base-image-other-repos
update-base-image-other-repos:
	./update_base_image_other_repos.sh

.PHONY: open-pr-check
open-pr-check:
	$(MAKE_ROOT)/../pr-scripts/open_pr_check.sh eks-distro-build-tooling

.PHONY: all
all: release

## --------------------------------------
## Document dynamic build targets
## --------------------------------------

base-images: ## Build and push standard full base image
minimal-images-base: ## Build and push minimal base image with base-system/ca-certs/user/nsswitch
minimal-images-base-nonroot: ## Build and push minimal base image nonroot variant
minimal-images-base-glibc: ## Build and push minimal base image with glibc
minimal-images-base-iptables: ## Build and push minimal base image with iptables + glibc
minimal-images-base-csi: ## Build and push minimal base image with common packages needed for csi drivers
minimal-images-base-git: ## Build and push minimal base image with git + libgit
minimal-images-base-docker-client: ## Build and push minimal base image with docker client
minimal-images-base-nginx: ## Build and push minimal base image with nginx for use by eks-anywhere-test
minimal-images-base-haproxy: ## Build and push minimal base image with haproxy for use by the kind haproxy image
minimal-images-base-kind: ## Build and push minimal base image with containerd and other deps for the kind base image

export-minimal-images-base: ## Export packages included in base minimal images
export-minimal-images-base-nonroot: ## Export packages included in base minimal images
export-minimal-images-base-glibc: ## Export packages included in glibc minimal images
export-minimal-images-base-iptables: ## Export packages included in iptables minimal images
export-minimal-images-base-csi: ## Export packages included in csi minimal images
export-minimal-images-base-git: ## Export packages included in git minimal images
export-minimal-images-base-docker-client: ## Export packages included in docker client minimal images
export-minimal-images-base-nginx: ## Export packages included in nginx minimal images
export-minimal-images-base-haproxy: ## Export packages included in haproxy minimal images
export-minimal-images-base-kind: ## Export packages included in kind minimal images

base-update:  ## Check for out of date packages on standard full base image and push new
minimal-base-update: ## Check for out of date packages on minimal base image and push new
minimal-base-nonroot-update: ## Check for out of date packages on minimal nonroot base image and push new
minimal-base-glibc-update: ## Check for out of date packages on minimal glibc base image and push new
minimal-base-iptables-update: ## Check for out of date packages on minimal iptables base image and push new
minimal-base-csi-update: ## Check for out of date packages on minimal csi base image and push new
minimal-base-git-update: ## Check for out of date packages on minimal git base image and push new
minimal-base-docker-client-update: ## Check for out of date packages on minimal docker client base image and push new
minimal-base-nginx: ## Check for out of date packages on minimal nginx base image and push new
minimal-base-haproxy: ## Check for out of date packages on minimal haproxy base image and push new
minimal-base-kind: ## Check for out of date packages on minimal kind base image and push new

base-create-pr:  ## Update standard base image tag if pushed
minimal-base-create-pr: ## Update minimal base image tag if pushed
minimal-base-nonroot-create-pr: ## Update minimal base nonroot image tag if pushed
minimal-base-glibc-create-pr: ## Update minimal base glibc image tag if pushed
minimal-base-iptables-create-pr: ## Update minimal base iptables image tag if pushed
minimal-base-csi-create-pr: ## Update minimal base csi image tag if pushed
minimal-base-git-create-pr: ## Update minimal base git image tag if pushed
minimal-base-docker-client-create-pr: ## Update minimal base docker client image tag if pushed
minimal-base-nginx-create-pr: ## Update minimal base nginx image tag if pushed
minimal-base-haproxy-create-pr: ## Update minimal base haproxy image tag if pushed
minimal-base-kind-create-pr: ## Update minimal base kind image tag if pushed
