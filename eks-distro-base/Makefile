# Disable built-in rules and variables
MAKEFLAGS+=--no-builtin-rules --warn-undefined-variables
SHELL=bash
.SHELLFLAGS:=-eu -o pipefail -c
.SUFFIXES:
.SECONDEXPANSION:

BASE_DIRECTORY=$(shell git rev-parse --show-toplevel)
MAKE_ROOT=$(BASE_DIRECTORY)/eks-distro-base

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
BASE_IMAGE_REPO?=$(IMAGE_REPO)
JOB_TYPE?=

# base and minimal-base use al2 as the base image
AL_TAG?=2
# tag al2 build with latest.2 and latest for backward compat
LATEST=$(if $(filter $(AL_TAG),2022),latest.2022,latest latest.2)

PLATFORMS?=linux/amd64,linux/arm64

IMAGE_TAG?=$(shell date "+%F-%s")
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(call ADD_VERSIONED_TO_TAG,$(IMAGE_TAG))

BASE_IMAGE_NAME?=eks-distro-base
BUILDER_IMAGE_NAME?=$(BASE_IMAGE_NAME)-builder

# if the image was built, either via this being a pre/post submit job
# or a periodic which pushed and created the -pushed file
# use the current IMAGE_TAG as the tag
# if not, use the image tag that will be pulled from the TAG_FILE
BASE_IMAGE_TAG_FROM_FILE=$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME))
BUILT_IMAGE_TAG_FROM_FILE=$(call BASE_TAG_FROM_TAG_FILE,$(IMAGE_NAME:%-builder=%)$(VERSIONED_VARIANT))
BASE_IMAGE_TAG=$(if $(or \
	$(and $(JOB_TYPE), $(JOB_TYPE),$(filter $(JOB_TYPE), presubmit postsubmit)), \
	$(filter $(shell cat $(MAKE_ROOT)/$(BASE_IMAGE_NAME)-pushed), true)),$(IMAGE_TAG),$(BASE_IMAGE_TAG_FROM_FILE))

BASE_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(BASE_IMAGE_TAG)
BUILDER_IMAGE=$(BASE_IMAGE_REPO)/$(BUILDER_IMAGE_NAME):$(BASE_IMAGE_TAG)
BUILT_BUILDER_IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME)-builder:$(call ADD_VERSIONED_TO_TAG,$(IMAGE_TAG))

LATEST_TAGS=$(foreach tag,$(LATEST),$(IMAGE_REPO)/$(IMAGE_NAME):$(if $(VERSIONED_VARIANT),$(VERSIONED_VARIANT)-$(tag),$(tag)))
LATEST_IMAGE=$(shell echo $(LATEST_TAGS) | sed "s/ \+/,/g")

MINIMAL_VARIANTS=base base-nonroot base-glibc base-iptables base-nsenter base-docker-client base-nginx base-csi-ebs base-csi base-kind base-haproxy base-git base-python3.9 #base-python3.7 base-python3.8
IMAGE_TARGETS=standard-images $(addprefix minimal-images-, $(MINIMAL_VARIANTS))
UPDATE_TARGETS=standard-update $(addprefix minimal-update-, $(MINIMAL_VARIANTS))
CREATE_PR_TARGETS=standard-create-pr $(addprefix minimal-create-pr-, $(MINIMAL_VARIANTS))

ALL_IMAGE_NAMES=eks-distro-base $(foreach variant,$(MINIMAL_VARIANTS),eks-distro-minimal-$(variant) eks-distro-minimal-$(variant)-builder)

OUTPUT_DEBUG_LOG?=
IMAGE_BUILD_ARGS?=
VERSIONED_VARIANT?=
BUILD_DEPS?=false
EXPORT_NAME?=

REMOVE_VERSIONED=$(if $(VERSIONED_VARIANT),$(1:%$(VERSIONED_VARIANT)=%),$(1))
ADD_VERSIONED_TO_TAG=$(if $(VERSIONED_VARIANT),$(VERSIONED_VARIANT)-$(1),$(1))

ALL_MINIMAL_IMAGES_TARGETS=$(foreach variant,$(MINIMAL_VARIANTS),minimal-images-$(variant))
ALL_BUILDER_MINIMAL_IMAGES_TARGETS=$(foreach variant,$(MINIMAL_VARIANTS),builder-minimal-images-$(variant))
ALL_FINAL_MINIMAL_IMAGES_TARGETS=$(foreach variant,$(MINIMAL_VARIANTS),final-minimal-images-$(variant))
ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS=$(foreach variant,$(MINIMAL_VARIANTS),packages-export-minimal-images-$(variant))
ALL_VALIDATE_IMAGES_MINIMAL_TARGETS=$(foreach variant,$(MINIMAL_VARIANTS),validate-minimal-images-$(variant))
ALL_TEST_MINIMAL_IMAGES_TARGETS=$(foreach variant,$(MINIMAL_VARIANTS),test-minimal-images-$(variant))

# if wanting to build the base image, for use locally or in presubmits
# returns the base image target needed
# $1 - minimal images variant
MINIMAL_IMAGES_BASE_IMAGE=$(and $(filter true,$(BUILD_DEPS)),\
	$(if $(filter-out base,$(1)),minimal-images-$(BASE_IMAGE_NAME:eks-distro-minimal-%=%),standard-images))

define BASE_TAG_FROM_TAG_FILE
$(shell yq e ".al$(AL_TAG).\"$(1)\"" $(MAKE_ROOT)/../EKS_DISTRO_TAG_FILE.yaml)
endef


define BUILDCTL
	$(MAKE_ROOT)/../scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt filename=$(DOCKERFILE) \
		--opt platform=$(PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--opt build-arg:BUILT_BUILDER_IMAGE=$(BUILT_BUILDER_IMAGE) \
		--opt build-arg:EXPORT_NAME=$(EXPORT_NAME) \
		--opt build-arg:OUTPUT_DEBUG_LOG=$(OUTPUT_DEBUG_LOG) \
		--opt build-arg:VERSIONED_VARIANT=$(VERSIONED_VARIANT) \
		--progress plain \
		--local dockerfile=./ \
		--local context=. \
		--opt target=$(IMAGE_TARGET) \
		--output type=$(IMAGE_OUTPUT_TYPE),oci-mediatypes=true,\"name=$(IMAGE),$(LATEST_IMAGE)\",$(IMAGE_OUTPUT)
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

.PHONY: open-pr-check
open-pr-check:
	${MAKE_ROOT}/../pr-scripts/update_local_branch.sh eks-distro-build-tooling
	$(MAKE_ROOT)/../pr-scripts/open_pr_check.sh eks-distro-build-tooling

##@ Image Targets

.PHONY: minimal-images-% $(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS) \
	$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS) $(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS) $(ALL_TEST_MINIMAL_IMAGES_TARGETS)

# There is no local images target since the minimal images build on each other we need a registry to push to
# in prow we run a docker registry as a sidecar
# see the README.md on how to run these targets locally

# base image overides
standard-images: BASE_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:$(AL_TAG)
standard-images: BUILDER_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:$(AL_TAG)

# images with custom "base" targets
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): DOCKERFILE=Dockerfile.minimal-helpers
final-minimal-images-base final-minimal-images-base-nonroot final-minimal-images-base-haproxy final-minimal-images-base-nginx: DOCKERFILE=Dockerfile.$(VARIANT)

# dep tree
%-minimal-images-base: BUILDER_IMAGE:=$(BASE_IMAGE)
%-minimal-images-base: BASE_IMAGE=scratch

# using %inimal to match all the minimal targets
%inimal-images-base-nonroot %inimal-images-base-glibc: BASE_IMAGE_NAME=eks-distro-minimal-base
%inimal-images-base-iptables %inimal-images-base-csi %inimal-images-base-git %inimal-images-base-docker-client \
	%inimal-images-base-nginx %inimal-images-base-haproxy %inimal-images-base-csi-ebs %inimal-images-base-nsenter \
	%inimal-images-base-python3.7 %inimal-images-base-python3.8 %inimal-images-base-python3.9: BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
%inimal-images-base-kind: BASE_IMAGE_NAME=eks-distro-minimal-base-iptables

# python variants
%-minimal-images-base-python3.7 %inimal-update-base-python3.7 %inimal-create-pr-base-python3.7: VERSIONED_VARIANT=3.7
%-minimal-images-base-python3.8 %inimal-update-base-python3.8 %inimal-create-pr-base-python3.8: VERSIONED_VARIANT=3.8
%-minimal-images-base-python3.9 %inimal-update-base-python3.9 %inimal-create-pr-base-python3.9: VERSIONED_VARIANT=3.9

# push standard/builder/base image targets
standard-images final-minimal-images-% builder-minimal-images-%: IMAGE_OUTPUT_TYPE=image
standard-images final-minimal-images-% builder-minimal-images-%: IMAGE_OUTPUT=push=true

# Standard distro-base image build
standard-images: DOCKERFILE=Dockerfile.base
standard-images: IMAGE_TARGET=final
standard-images: IMAGE_NAME=eks-distro-base
standard-images:
	if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./check_update.sh $(IMAGE_NAME) $(AL_TAG); \
	fi
	$(call BUILDCTL)

$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS) \
	$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS) $(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS) $(ALL_TEST_MINIMAL_IMAGES_TARGETS): VARIANT=minimal-$(call REMOVE_VERSIONED,$(VARIANT_SHORT_NAME))
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS) \
	$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS) $(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS) $(ALL_TEST_MINIMAL_IMAGES_TARGETS): IMAGE_NAME=eks-distro-$(VARIANT)

$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS): DOCKERFILE?=Dockerfile.$(VARIANT)

# Relying on secndary expansion for this target so that pre-reqs can use the variant var
$(ALL_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:minimal-images-%=%)
$(ALL_MINIMAL_IMAGES_TARGETS): $$(call MINIMAL_IMAGES_BASE_IMAGE,$$(VARIANT_SHORT_NAME)) builder-minimal-images-$$(VARIANT_SHORT_NAME) \
		final-minimal-images-$$(VARIANT_SHORT_NAME) packages-export-minimal-images-$$(VARIANT_SHORT_NAME) \
		validate-minimal-images-$$(VARIANT_SHORT_NAME) test-minimal-images-$$(VARIANT_SHORT_NAME)
	@echo Building $(VARIANT_SHORT_NAME) complete!

$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:builder-minimal-images-%=%)
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): IMAGE_TARGET=builder
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): IMAGE_NAME=eks-distro-$(VARIANT)-builder
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS):
	$(call BUILDCTL)

$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:final-minimal-images-%=%)
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): IMAGE_TARGET=final
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): builder-minimal-images-$$(VARIANT_SHORT_NAME)
	if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./check_update.sh $(IMAGE_NAME) $(AL_TAG) $(VERSIONED_VARIANT); \
	fi
	$(call BUILDCTL)

$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:packages-export-minimal-images-%=%)
# to make the file names `kind` vs `base-kind`
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): EXPORT_NAME=$(if $(and $(filter-out minimal-base,$(VARIANT)),$(filter-out minimal-base-nonroot,$(VARIANT))),$(VARIANT:minimal-base-%=%)$(VERSIONED_VARIANT),base)
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_TARGET=export
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT_TYPE=local
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT_DIR=$(MAKE_ROOT)/../eks-distro-base-minimal-packages/$(AL_TAG)
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT=dest=$(IMAGE_OUTPUT_DIR)
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): DOCKERFILE=Dockerfile.minimal-helpers
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS):
	$(call BUILDCTL)
	if [ -f $(IMAGE_OUTPUT_DIR)/$(EXPORT_NAME) ]; then \
		mv $(IMAGE_OUTPUT_DIR)/$(EXPORT_NAME)* $(IMAGE_OUTPUT_DIR)/$(subst /,_,$(PLATFORMS))/; \
	fi

$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): VARIANT_SHORT_NAME=$(@:validate-minimal-images-%=%)
$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): IMAGE_TARGET=validate
$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): IMAGE_OUTPUT_TYPE=local
$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): IMAGE_OUTPUT=dest=/tmp
$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): DOCKERFILE=Dockerfile.minimal-helpers
$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS):
	$(call BUILDCTL)

$(ALL_TEST_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:test-minimal-images-%=%)
$(ALL_TEST_MINIMAL_IMAGES_TARGETS):
	if command -v docker &> /dev/null && docker info > /dev/null 2>&1 ; then \
		$(MAKE_ROOT)/tests/run_tests.sh $(IMAGE_REPO) $(call ADD_VERSIONED_TO_TAG,$(IMAGE_TAG)) $(AL_TAG) $(PLATFORMS) check_$(VARIANT_SHORT_NAME); \
	fi


# These vars are all to make sure we pull the public images from ecr vs building locally
# for use when periodic does not properly update packages and we want to update them manually
.PHONY: packages-export-all-minimal-images
packages-export-all-minimal-images: IMAGE_REPO=public.ecr.aws/eks-distro-build-tooling
packages-export-all-minimal-images: IMAGE_TAG=$(BUILT_IMAGE_TAG_FROM_FILE)
packages-export-all-minimal-images: $(addprefix packages-export-minimal-images-, $(MINIMAL_VARIANTS))

# These vars are all to make sure we pull the public images from ecr vs building locally
# for use to validate newly built images which have been pushed by the postsubmit
.PHONY: test-all-minimal-images
test-all-minimal-images: IMAGE_REPO=public.ecr.aws/eks-distro-build-tooling
test-all-minimal-images: IMAGE_TAG=$(BUILT_IMAGE_TAG_FROM_FILE)
test-all-minimal-images: $(addprefix test-minimal-images-, $(MINIMAL_VARIANTS))

##@ Update targets

.PHONY: update-%
update-%:
	echo "false" > $(MAKE_ROOT)/$(IMAGE_NAME)$(VERSIONED_VARIANT)-pushed
	$(eval RETURN_MESSAGE="$(shell ./check_update.sh $(IMAGE_NAME) $(AL_TAG) $(VERSIONED_VARIANT) )")
	if [ $(RETURN_MESSAGE) = "Updates required" ]; then \
		$(MAKE) $(UPDATE_TARGET); \
		echo "true" > $(MAKE_ROOT)/$(IMAGE_NAME)$(VERSIONED_VARIANT)-pushed; \
	elif [ $(RETURN_MESSAGE) = "Error" ]; then \
		exit 1; \
	fi

.PHONY: standard-update
standard-update: UPDATE_TARGET=standard-images
standard-update: IMAGE_NAME=eks-distro-base
standard-update: update-standard 

.PHONY: minimal-update-%
minimal-update-%: VARIANT_SHORT_NAME=$*
minimal-update-%: UPDATE_TARGET=minimal-images-$(VARIANT_SHORT_NAME)
minimal-update-%: VARIANT=minimal-$(call REMOVE_VERSIONED,$(VARIANT_SHORT_NAME))
minimal-update-%: IMAGE_NAME=eks-distro-$(VARIANT)
minimal-update-%: update-%
	@echo "Done $(@)"

##@ PR Targets

# Update tag files in and create PR against eks-distro-build-tooling and eks-distro repos
.PHONY: create-pr-%
create-pr-%: ensure-repo-owner
	if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./update_base_image.sh $(call ADD_VERSIONED_TO_TAG,$(IMAGE_TAG)) $(IMAGE_NAME) $(AL_TAG); \
	elif [ "$(shell cat $(MAKE_ROOT)/$(IMAGE_NAME)-pushed)" = "true" ]; then \
		./update_base_image.sh $(call ADD_VERSIONED_TO_TAG,$(IMAGE_TAG)) $(IMAGE_NAME) $(AL_TAG); \
	fi

.PHONY: standard-create-pr
standard-create-pr: IMAGE_NAME=eks-distro-base
standard-create-pr: create-pr-standard

.PHONY: minimal-create-pr-%
minimal-create-pr-%: IMAGE_NAME=eks-distro-minimal-$*
minimal-create-pr-%: create-pr-%
	@echo "Done $(@)"

.PHONY: ensure-repo-owner
ensure-repo-owner:
ifndef REPO_OWNER
	$(error No org information was provided, please set and export REPO_OWNER environment variable. \
	This is used to raise a pull request against your org after updating tags in the respective files.)
endif


##@ Primary Targets

.PHONY: build
build: PLATFORMS=linux/amd64
build: buildkit-check $(IMAGE_TARGETS)

.PHONY: release
release: buildkit-check $(IMAGE_TARGETS)

.PHONY: create-pr
create-pr: $(CREATE_PR_TARGETS)
	$(MAKE_ROOT)/../pr-scripts/create_pr.sh eks-distro-build-tooling 'EKS_DISTRO*_TAG_FILE*'

.PHONY: update
update: buildkit-check open-pr-check $(UPDATE_TARGETS)

.PHONY: update-base-image-other-repos
update-base-image-other-repos:
	./update_base_image_other_repos.sh

.PHONY: all
all: release


##@ Local Targets

# for local development only
.PHONY: minimal-base-test
minimal-base-test: 
	./tests/run_tests.sh $(IMAGE_REPO) $(IMAGE_TAG)

.PHONY: %/create-ecr-repo
%/create-ecr-repo: IMAGE_NAME=$*
%/create-ecr-repo:
	cmd=( ecr ); \
	if [[ "${IMAGE_REPO}" =~ ^public\.ecr\.aws/ ]]; then \
		cmd=( ecr-public --region us-east-1 ); \
	fi; \
	repo=$(IMAGE_NAME); \
	if ! aws $${cmd[*]} describe-repositories --repository-name "$$repo" > /dev/null 2>&1; then \
		aws $${cmd[*]} create-repository --repository-name "$$repo"; \
	fi;

.PHONY: create-ecr-repos
create-ecr-repos: # Create repos in ECR for project images for local testing
create-ecr-repos: $(foreach image,$(ALL_IMAGE_NAMES),$(image)/create-ecr-repo)


## --------------------------------------
## Document dynamic build targets
## --------------------------------------

standard-images: ## Build and push standard full base image
minimal-images-base: ## Build and push minimal base image with base-system/ca-certs/user/nsswitch
minimal-images-base-nonroot: ## Build and push minimal base image nonroot variant
minimal-images-base-glibc: ## Build and push minimal base image with glibc
minimal-images-base-iptables: ## Build and push minimal base image with iptables + glibc
minimal-images-base-csi: ## Build and push minimal base image with common packages needed for csi drivers
minimal-images-base-csi-ebs: ## Build and push minimal base image with common packages needed specifically for the ebs csi driver
minimal-images-base-git: ## Build and push minimal base image with git + libgit
minimal-images-base-docker-client: ## Build and push minimal base image with docker client
minimal-images-base-nginx: ## Build and push minimal base image with nginx for use by eks-anywhere-test
minimal-images-base-haproxy: ## Build and push minimal base image with haproxy for use by the kind haproxy image
minimal-images-base-kind: ## Build and push minimal base image with containerd and other deps for the kind base image
minimal-images-base-nsenter: ## Build and push minimal base image with nsenter binary for privileged access to host namespaces
minimal-images-base-python3.9: ## Build and push minimal base image with python3

packages-export-minimal-images-base: ## Export packages included in base minimal images
packages-export-minimal-images-base-nonroot: ## Export packages included in base minimal images
packages-export-minimal-images-base-glibc: ## Export packages included in glibc minimal images
packages-export-minimal-images-base-iptables: ## Export packages included in iptables minimal images
packages-export-minimal-images-base-csi: ## Export packages included in csi minimal images
packages-export-minimal-images-base-csi-ebs: ## Export packages included in ebs csi minimal images
packages-export-minimal-images-base-git: ## Export packages included in git minimal images
packages-export-minimal-images-base-docker-client: ## Export packages included in docker client minimal images
packages-export-minimal-images-base-nginx: ## Export packages included in nginx minimal images
packages-export-minimal-images-base-haproxy: ## Export packages included in haproxy minimal images
packages-export-minimal-images-base-kind: ## Export packages included in kind minimal images
packages-export-minimal-images-base-nsenter: ## Export packages included in nsenter minimal images
packages-export-minimal-images-base-python3.9: ## Export packages included in python3 minimal images

standard-update:  ## Check for out of date packages on standard full base image and push new
minimal-update-base: ## Check for out of date packages on minimal base image and push new
minimal-update-base-nonroot: ## Check for out of date packages on minimal nonroot base image and push new
minimal-update-base-glibc: ## Check for out of date packages on minimal glibc base image and push new
minimal-update-base-iptables: ## Check for out of date packages on minimal iptables base image and push new
minimal-update-base-csi: ## Check for out of date packages on minimal csi base image and push new
minimal-update-base-csi-ebs: ## Check for out of date packages on minimal ebs csi base image and push new
minimal-update-base-git: ## Check for out of date packages on minimal git base image and push new
minimal-update-base-docker-client: ## Check for out of date packages on minimal docker client base image and push new
minimal-update-base-nginx: ## Check for out of date packages on minimal nginx base image and push new
minimal-update-base-haproxy: ## Check for out of date packages on minimal haproxy base image and push new
minimal-update-base-kind: ## Check for out of date packages on minimal kind base image and push new
minimal-update-base-nsenter: ## Check for out of date packages on minimal nsenter base image and push new
minimal-update-base-python3.9: ## Check for out of date packages on minimal python3 base image and push new

standard-create-pr:  ## Update standard base image tag if pushed
minimal-base-create-pr: ## Update minimal base image tag if pushed
minimal-base-nonroot-create-pr: ## Update minimal base nonroot image tag if pushed
minimal-base-glibc-create-pr: ## Update minimal base glibc image tag if pushed
minimal-base-iptables-create-pr: ## Update minimal base iptables image tag if pushed
minimal-base-csi-create-pr: ## Update minimal base csi image tag if pushed
minimal-base-csi-ebs-create-pr: ## Update minimal base ebs csi image tag if pushed
minimal-base-git-create-pr: ## Update minimal base git image tag if pushed
minimal-base-docker-client-create-pr: ## Update minimal base docker client image tag if pushed
minimal-base-nginx-create-pr: ## Update minimal base nginx image tag if pushed
minimal-base-haproxy-create-pr: ## Update minimal base haproxy image tag if pushed
minimal-base-kind-create-pr: ## Update minimal base kind image tag if pushed
minimal-base-nsenter-create-pr: ## Update minimal base nsenter image tag if pushed
minimal-base-python3.9-create-pr: ## Update minimal base python3 image tag if pushed
