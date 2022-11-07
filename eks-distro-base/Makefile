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
TEST_IMAGE_REPO?=localhost:5000
IGNORE_NO_CACHE?=false
# ******************** Helpers ******************************
# For replacing commas or with commas, it needs to be in a var
COMMA=,

# TODO: this exist in the gmsl, https://gmsl.sourceforge.io/
# look into introducting gmsl for things like this
# this function gets called a few dozen times and the alternative of using shell with tr takes
# noticeablely longer
TO_UPPER = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst \
	f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst \
	m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst \
	t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$(subst -,_,$(1))))))))))))))))))))))))))))

TO_LOWER = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst \
	F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst \
	M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst \
	T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$(subst _,-,$(1))))))))))))))))))))))))))))

# $1 - potential override variable name
# $2 - value if variable not set
# returns value of override var if one is set, otherwise returns $(2)
IF_OVERRIDE_VARIABLE=$(if $(filter undefined,$(origin $1)),$(2),$(value $(1)))

# if wanting to build the base image, for use locally or in presubmits
# returns the base image target needed
# $1 - minimal images variant
MINIMAL_IMAGES_BASE_IMAGE=$(and $(filter true,$(BUILD_DEPS)),\
	$(if $(filter-out base,$(1)),minimal-images-$(BASE_IMAGE_NAME:eks-distro-minimal-%=%),standard-images))

# $1 - image name
# $2 - versioned variant
CHECK_UPDATE_FILE_PATH=$(MAKE_ROOT)/check-update/$(1)$(if $(2),-$(2),)

# overridden in dry run tests to track calls
# $1 - image name
# $2 - AL_TAG
# $3 - versioned variant
MOCK_CHECK_UPDATE?=
CHECK_UPDATE?=$(if $(MOCK_CHECK_UPDATE), \
	$(info check-update $(1) $(2) $(3))$(shell mkdir -p $(MAKE_ROOT)/check-update && echo $(MOCK_CHECK_UPDATE) > $(call CHECK_UPDATE_FILE_PATH,$(1),$(3))), \
	$(shell ./check_update.sh $(1) $(2) $(3)) \
)
CHECK_UPDATE_IF_PROW?=$(shell if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then $(if $(MOCK_CHECK_UPDATE),echo,) ./check_update.sh $(1) $(2) $(3); fi)

# $1 - versioned image tag
# $2 - image name
# $3 - al tag
MOCK_UPDATE_BASE_IMAGE?=
UPDATE_BASE_IMAGE?=$(if $(MOCK_UPDATE_BASE_IMAGE), \
	$(info update_base_image.sh $(1) $(2) $(3)), \
	$(shell ./update_base_image.sh $(1) $(2) $(3)) \
)

MOCK_CAT_PUSHED_FILE?=
# $1 - pushed file path
CAT_PUSHED_FILE=$(if $(MOCK_CAT_PUSHED_FILE),$(info cat pushed file $(1))$(MOCK_CAT_PUSHED_FILE),$(shell [ -f $(1) ] && cat $(1)))

EKS_DISTRO_TAG_FILE=$(MAKE_ROOT)/../EKS_DISTRO_TAG_FILE.yaml

# $1 - image name
MOCK_BASE_TAG_FROM_TAG_FILE?=
BASE_TAG_FROM_TAG_FILE=$(if $(MOCK_BASE_TAG_FROM_TAG_FILE),$(info tag from file for $(1))$(MOCK_BASE_TAG_FROM_TAG_FILE),$(shell [[ -f $(EKS_DISTRO_TAG_FILE) ]] && yq e ".al$(AL_TAG).\"$(1)\"" $(EKS_DISTRO_TAG_FILE)))

# $1 - base image name
# $2 - image tag if not reading from file, empty value will default to IMAGE_TAG
#    intended to be versioned_image_tag when getting tag for versioned variant
IMAGE_TAG_FOR_VARIANT=$(if $(or \
	$(and $(JOB_TYPE),$(filter $(JOB_TYPE),presubmit postsubmit)), \
	$(filter true, $(call CAT_PUSHED_FILE,$(MAKE_ROOT)/$(1)-pushed))),$(or $(2),$(IMAGE_TAG)),$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME)) \
)
# ************************************************************

# base and minimal-base use al2 as the base image
AL_TAG?=2

BUILD_DEPS?=false
OUTPUT_DEBUG_LOG?=

GLIBC_VARIANT_NAME=eks-distro-minimal-base-glibc

# ******************** Image Setup ***************************
IMAGE_TAG?=$(shell date "+%F-%s")
VERSIONED_IMAGE_TAG?=$(call ADD_VERSIONED_VARIANT,$(IMAGE_TAG))
IMAGE?=$(IMAGE_REPO)/$(IMAGE_COMPONENT):$(VERSIONED_IMAGE_TAG)
# ************************************************************

# ******************** Base Image Setup **********************
BASE_IMAGE_NAME?=eks-distro-base
BASE_IMAGE_COMPONENT?=$(BASE_IMAGE_NAME)
VERSIONED_BASE_IMAGE_TAG?=$(call ADD_BASE_VERSIONED_VARIANT,$(BASE_IMAGE_TAG))

# if the image was built, either via this being a pre/post submit job
# or a periodic which pushed and created the -pushed file
# use the current IMAGE_TAG as the tag
# if not, use the image tag that will be pulled from the TAG_FILE
BASE_IMAGE_TAG_FROM_FILE=$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME))
BUILT_IMAGE_TAG_FROM_FILE=$(call BASE_TAG_FROM_TAG_FILE,$(IMAGE_NAME:%-builder=%))
BASE_IMAGE_TAG=$(call IMAGE_TAG_FOR_VARIANT,$(BASE_IMAGE_NAME),)

BASE_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_COMPONENT):$(VERSIONED_BASE_IMAGE_TAG)
BUILDER_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_COMPONENT)-builder:$(VERSIONED_BASE_IMAGE_TAG)
# Built image for current variant, builder images are their own image
# this is used during the final build stage to copy /newroot from
BUILT_BUILDER_IMAGE?=$(IMAGE_REPO)/$(IMAGE_COMPONENT)-builder:$(VERSIONED_IMAGE_TAG)
# ************************************************************

# ******************** Latest Setup **************************
LATEST_TAGS=$(foreach tag,$(LATEST),$(IMAGE_REPO)/$(IMAGE_COMPONENT):$(tag))
LATEST_IMAGE=$(shell echo $(LATEST_TAGS) | sed "s/ \+/,/g")
# ************************************************************

# ****************** COMPILER BASE VARIANTS ******************
BASE_COMPILER_VARIANT_VERSIONS=base yum gcc
# ************************************************************

# ****************** PYTHON VARIANTS *************************
PYTHON_VARIANT_NAME=eks-distro-minimal-base-python
BASE_PYTHON_VARIANT_VERSIONS=3.9
# ************************************************************

# ************** MINIMAL VARIANT MAGIC VARS ******************

# Foreach minimal variant (+ versioned variants) new vars are created to make it easier to override
# target prereqs and vars. The vars will follow the patterns:
#  - ALL_MINIMAL_IMAGE_TARGETS_FOR_${variant}
#  - BUILDER_MINIMAL_IMAGE_TARGETS_FOR_${variant}
#  - BUILDER_MINIMAL_IMAGE_TARGETS_FOR_${variant}
#  - ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_${varaint} - for versioned variants
#  - BUILDER_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_${varaint} - for versioned variants

VARIANTS=base base-nonroot base-glibc base-iptables base-nsenter base-docker-client base-nginx \
	base-csi-ebs base-csi base-kind base-haproxy base-git base-compiler \
	base-python

ALL_IMAGE_NAMES=eks-distro-base

MINIMAL_IMAGE_TARGET_PREFIXS=minimal-images $(addsuffix -minimal-images,builder final packages-export validate test) minimal-update minimal-create-pr update
$(foreach variant,$(VARIANTS), \
	$(eval VARIANT_UPPER:=$(call TO_UPPER,$(variant))) \
	$(eval VARIANT_VERSIONS:=$(call IF_OVERRIDE_VARIABLE,$(VARIANT_UPPER)_VARIANT_VERSIONS,)) \
	$(eval ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_$(VARIANT_UPPER):=) \
	$(eval ALL_MINIMAL_IMAGE_TARGETS_FOR_$(VARIANT_UPPER):=$(addsuffix -$(variant),$(MINIMAL_IMAGE_TARGET_PREFIXS))) \
	$(eval BUILDER_MINIMAL_IMAGE_TARGETS_FOR_$(VARIANT_UPPER):=builder-minimal-images-$(variant)) \
	$(eval FINAL_MINIMAL_IMAGE_TARGETS_FOR_$(VARIANT_UPPER):=final-minimal-images-$(variant)) \
	$(eval ALL_IMAGE_NAMES+=eks-distro-minimal-$(variant) eks-distro-minimal-$(variant)-builder) \
	$(if $(VARIANT_VERSIONS),,$(eval MINIMAL_VARIANTS+=$(variant))) \
	$(foreach version,$(VARIANT_VERSIONS), \
		$(eval MINIMAL_VARIANTS+=$(variant)-$(version)) \
		$(eval ALL_VERSION_VARIANT_VAR:=ALL_MINIMAL_IMAGE_TARGETS_FOR_$(VARIANT_UPPER)_$(call TO_UPPER,$(version))) \
		$(eval $(ALL_VERSION_VARIANT_VAR):=$(addsuffix -$(variant)-$(version),$(MINIMAL_IMAGE_TARGET_PREFIXS))) \
		$(eval ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_$(VARIANT_UPPER)+=$(value $(ALL_VERSION_VARIANT_VAR))) \
	) \
	$(eval BUILDER_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_$(VARIANT_UPPER):=$(addprefix builder-minimal-images-$(variant)-,$(VARIANT_VERSIONS))) \
)

ALL_MAIN_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),minimal-images-$(variant))
ALL_BUILDER_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),builder-minimal-images-$(variant))
ALL_FINAL_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),final-minimal-images-$(variant))
ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),packages-export-minimal-images-$(variant))
ALL_VALIDATE_IMAGES_MINIMAL_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),validate-minimal-images-$(variant))
ALL_TEST_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),test-minimal-images-$(variant))
ALL_UPDATE_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),minimal-update-$(variant))
ALL_CREATE_PR_MINIMAL_IMAGES_TARGETS:=$(foreach variant,$(MINIMAL_VARIANTS),minimal-create-pr-$(variant))

ALL_MINIMAL_IMAGE_TARGETS=$(ALL_MAIN_MINIMAL_IMAGES_TARGETS) $(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS) $(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS) \
	$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS) $(ALL_TEST_MINIMAL_IMAGES_TARGETS) $(ALL_UPDATE_MINIMAL_IMAGES_TARGETS) $(ALL_CREATE_PR_MINIMAL_IMAGES_TARGETS)

# ************************************************************

# ************** VERSION VARIANTS ***************************
VERSIONED_VARIANT?=
# # if the base image is a versioned version of the base image, like compiler-base (base being the "version") or compiler-base:yum
BASE_VERSIONED_VARIANT?=

# $1 - tag to prepend version info to
ADD_VERSIONED_VARIANT=$(if $(VERSIONED_VARIANT),$(VERSIONED_VARIANT)-$(1),$(1))
ADD_BASE_VERSIONED_VARIANT=$(if $(BASE_VERSIONED_VARIANT),$(BASE_VERSIONED_VARIANT)-$(1),$(1))
# ************************************************************

# ************** FINAL TARGETS *******************************
IMAGE_TARGETS=standard-images $(addprefix minimal-images-, $(MINIMAL_VARIANTS))
UPDATE_TARGETS=standard-update $(addprefix minimal-update-, $(MINIMAL_VARIANTS))
CREATE_PR_TARGETS=standard-create-pr $(addprefix minimal-create-pr-, $(MINIMAL_VARIANTS))
# ************************************************************

BUILDCTL_IMAGE_TAGS=,oci-mediatypes=true,\"name=$(IMAGE),$(LATEST_IMAGE)\"
BUILDCTL_BUILD_ARGS?=
PLATFORMS?=linux/amd64,linux/arm64

define BUILDCTL
	$(MAKE_ROOT)/../scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt filename=$(DOCKERFILE) \
		--opt platform=$(PLATFORMS) \
		--opt build-arg:OUTPUT_DEBUG_LOG=$(OUTPUT_DEBUG_LOG) \
		$(foreach BUILD_ARG,$(BUILDCTL_BUILD_ARGS),--opt build-arg:$(BUILD_ARG)=$($(BUILD_ARG))) \
		--progress plain \
		--local dockerfile=./ \
		--local context=. \
		--opt target=$(IMAGE_TARGET) \
		$(if $(filter local,$(IMAGE_OUTPUT_TYPE)),,--export-cache type=inline) \
		$(foreach IMPORT_CACHE,$(BUILDCTL_IMPORT_CACHE),--import-cache $(IMPORT_CACHE)) \
		$(if $(filter false,$(IGNORE_NO_CACHE)),$(BUILDCTL_NO_CACHE),) \
		--output type=$(IMAGE_OUTPUT_TYPE)$(if $(filter local,$(IMAGE_OUTPUT_TYPE)),,$(BUILDCTL_IMAGE_TAGS)),$(IMAGE_OUTPUT)
endef

define UPDATE_TARGET_BODY	
	@echo false > $(MAKE_ROOT)/$(IMAGE_NAME)-pushed
	$(call CHECK_UPDATE,$(IMAGE_COMPONENT),$(AL_TAG),$(VERSIONED_VARIANT))
	$(eval CHECK_UPDATE_RESULT:=$(shell cat $(call CHECK_UPDATE_FILE_PATH,$(IMAGE_COMPONENT),$(VERSIONED_VARIANT))))
	$(if $(filter error,$(CHECK_UPDATE_RESULT)),@exit 1,)
	$(if $(filter none,$(CHECK_UPDATE_RESULT)),@echo No updates for $(@),)
	$(if $(filter updates,$(CHECK_UPDATE_RESULT)),make $(UPDATE_TARGET) && @echo true > $(MAKE_ROOT)/$(IMAGE_NAME)-pushed)
endef

define CREATE_PR_TARGET_BODY
	$(if \
		$(or $(filter presubmit,$(JOB_TYPE)),$(filter postsubmit,$(JOB_TYPE)),$(filter true,$(call CAT_PUSHED_FILE,$(MAKE_ROOT)/$(IMAGE_NAME)))), \
		$(eval UPDATE_BASE_IMAGE_RESULT:=$(call UPDATE_BASE_IMAGE,$(VERSIONED_IMAGE_TAG),$(IMAGE_NAME),$(AL_TAG))) @echo Updated base image tag file, \
		$(shell echo No update) \
	)
endef

# There is no local images target since the minimal images build on each other we need a registry to push to
# in prow we run a docker registry as a sidecar
# see the README.md on how to run these targets locally

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

.PHONY: ensure-repo-owner
ensure-repo-owner:
ifndef REPO_OWNER
	$(error No org information was provided, please set and export REPO_OWNER environment variable. \
	This is used to raise a pull request against your org after updating tags in the respective files.)
endif

##@ Image Targets

# ****************** MINIMAL IMAGE DEFAULTS *********************

.PHONY: $(ALL_MINIMAL_IMAGE_TARGETS)

# Default variable values for minimal image targets, these targets are all fully expanded, ie no %, which means any future targets that intend to override this behavior
# need to be fully expanded
$(ALL_MINIMAL_IMAGE_TARGETS): VARIANT=minimal-$(VARIANT_SHORT_NAME)
$(ALL_MINIMAL_IMAGE_TARGETS): IMAGE_NAME=eks-distro-$(VARIANT)
$(ALL_MINIMAL_IMAGE_TARGETS): IMAGE_COMPONENT=$(IMAGE_NAME)
$(ALL_MINIMAL_IMAGE_TARGETS): BASE_IMAGE_COMPONENT=$(BASE_IMAGE_NAME)
$(ALL_MINIMAL_IMAGE_TARGETS): VERSIONED_VARIANT=
$(ALL_MINIMAL_IMAGE_TARGETS): BASE_VERSIONED_VARIANT=
$(ALL_MINIMAL_IMAGE_TARGETS): BUILDCTL_IMPORT_CACHE=
$(ALL_MINIMAL_IMAGE_TARGETS): BUILDCTL_NO_CACHE=
# tag al2 build with latest.2 and latest for backward compat
$(ALL_MINIMAL_IMAGE_TARGETS): LATEST=$(if $(filter $(AL_TAG),2022),latest-al22,latest latest.2 latest-al2)

# By default use the minimal-helpers dockerfile for the final stage since its just a copy
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): DOCKERFILE=Dockerfile.minimal-helpers

# By default use the specific dockerfile for the given variant
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS): DOCKERFILE?=Dockerfile.$(VARIANT)
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT_TYPE=image
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS) $(ALL_FINAL_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT=push=true

# Default build-args for given build stages
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): BUILDCTL_BUILD_ARGS=BASE_IMAGE BUILDER_IMAGE
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): BUILDCTL_BUILD_ARGS=BASE_IMAGE BUILT_BUILDER_IMAGE
# ***********************************************************

# ****************** BASE VARIANTS **************************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE): BUILDER_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_COMPONENT):$(BASE_IMAGE_TAG)
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE): BASE_IMAGE=scratch
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE): BASE_IMAGE_NAME=eks-distro-base
$(FINAL_MINIMAL_IMAGE_TARGETS_FOR_BASE): DOCKERFILE=Dockerfile.$(VARIANT)

$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_NONROOT): BASE_IMAGE_NAME=eks-distro-minimal-base
$(FINAL_MINIMAL_IMAGE_TARGETS_FOR_BASE_NONROOT): DOCKERFILE=Dockerfile.$(VARIANT)
# ***********************************************************

# ****************** GLIBC VARIANTS *************************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_GLIBC): BASE_IMAGE_NAME=eks-distro-minimal-base
# ***********************************************************

# ****************** IPTABLES VARIANTS **********************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_IPTABLES): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
# ***********************************************************

# ****************** CSI VARIANTS ***************************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_CSI): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
# ***********************************************************

# ****************** GIT VARIANTS ***************************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_GIT): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
# ***********************************************************

# ****************** DOCKER CLIENT VARIANTS *****************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_DOCKER_CLIENT): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
# ***********************************************************

# ****************** NGINX VARIANTS *************************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_NGINX): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
$(FINAL_MINIMAL_IMAGE_TARGETS_FOR_BASE_NGINX): DOCKERFILE=Dockerfile.$(VARIANT)
# ***********************************************************

# ****************** HAPROXY VARIANTS ***********************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_HAPROXY): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
$(FINAL_MINIMAL_IMAGE_TARGETS_FOR_BASE_HAPROXY): DOCKERFILE=Dockerfile.$(VARIANT)
# ***********************************************************

# ****************** CSI-EBS VARIANTS ***********************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_CSI_EBS): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
# ***********************************************************

# ****************** NSENTER VARIANTS ***********************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_NSENTER): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
# ***********************************************************

# ****************** KIND VARIANTS **************************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_KIND): BASE_IMAGE_NAME=eks-distro-minimal-base-iptables
# ***********************************************************

# ****************** PYTHON VARIANTS ************************
$(ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_PYTHON): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc
$(ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_PYTHON): DOCKERFILE=Dockerfile.minimal-base-python
$(ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_PYTHON): BUILDCTL_BUILD_ARGS+=VERSIONED_VARIANT

$(ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_PYTHON): IMAGE_COMPONENT=eks-distro-minimal-base-python
$(BUILDER_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_PYTHON): IMAGE_COMPONENT=eks-distro-minimal-base-python-builder

$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_PYTHON_3.9): VERSIONED_VARIANT=3.9

# ****************** COMPILER BASE VARIANTS ******************
.PHONY: compiler-base-images
compiler-base-images: $(addprefix minimal-images-base-compiler-,$(BASE_COMPILER_VARIANT_VERSIONS))

$(ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_COMPILER): DOCKERFILE=Dockerfile.minimal-base-compiler
$(ALL_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_COMPILER): IMAGE_COMPONENT=compiler-base
$(BUILDER_MINIMAL_IMAGE_VERSIONED_VARIANTS_TARGETS_FOR_BASE_COMPILER): IMAGE_COMPONENT=compiler-base-builder

$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_BASE): BASE_IMAGE_NAME=eks-distro-minimal-base-glibc

# ****************** COMPILER YUM ******************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_YUM): VERSIONED_VARIANT=yum
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_YUM): BUILDCTL_BUILD_ARGS+=VERSIONED_VARIANT
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_YUM): BASE_IMAGE_NAME=eks-distro-minimal-base-compiler-base
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_YUM): BASE_IMAGE_COMPONENT=compiler-base

# ****************** COMPILER GCC ******************
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_GCC): VERSIONED_VARIANT=gcc
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_GCC): BUILDCTL_BUILD_ARGS+=VERSIONED_VARIANT
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_GCC): BASE_IMAGE_NAME=eks-distro-minimal-base-compiler-yum
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_GCC): BASE_IMAGE_COMPONENT=compiler-base
$(ALL_MINIMAL_IMAGE_TARGETS_FOR_BASE_COMPILER_GCC): BASE_VERSIONED_VARIANT=yum
# ************************************************************

# ****************** STANDARD EKS-DISTRO IMAGE TARGETS *******
# Standard distro-base image build
standard-images: BASE_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:$(AL_TAG)
standard-images: BUILDER_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:$(AL_TAG)
standard-images: IMAGE_OUTPUT_TYPE=image
standard-images: IMAGE_OUTPUT=push=true
standard-images: DOCKERFILE=Dockerfile.base
standard-images: IMAGE_TARGET=final
standard-images: IMAGE_NAME=eks-distro-base
standard-images: IMAGE_COMPONENT=$(IMAGE_NAME)
standard-images: VERSIONED_VARIANT=
standard-images: BASE_VERSIONED_VARIANT=
standard-images: BUILDCTL_BUILD_ARGS=BASE_IMAGE
standard-images: BUILDCTL_IMPORT_CACHE=
standard-images: BUILDCTL_NO_CACHE=
# tag al2 build with latest.2 and latest for backward compat
standard-images: LATEST=$(if $(filter $(AL_TAG),2022),latest-al22,latest latest.2 latest-al2)
standard-images: buildkit-check
	@printf "Building standard eks-distro-base\n\n"
	$(call CHECK_UPDATE_IF_PROW,$(IMAGE_NAME),$(AL_TAG),)
	$(call BUILDCTL)

# ************************************************************


# Relying on secndary expansion for this target so that pre-reqs can use the variant var
$(ALL_MAIN_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:minimal-images-%=%)
$(ALL_MAIN_MINIMAL_IMAGES_TARGETS): buildkit-check $$(call MINIMAL_IMAGES_BASE_IMAGE,$$(VARIANT_SHORT_NAME)) builder-minimal-images-$$(VARIANT_SHORT_NAME) \
		final-minimal-images-$$(VARIANT_SHORT_NAME) packages-export-minimal-images-$$(VARIANT_SHORT_NAME) \
		validate-minimal-images-$$(VARIANT_SHORT_NAME) test-minimal-images-$$(VARIANT_SHORT_NAME)
	@printf "Building $(VARIANT_SHORT_NAME) complete!\n\n"

$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:builder-minimal-images-%=%)
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): IMAGE_TARGET=builder
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS): IMAGE_NAME=eks-distro-$(VARIANT)-builder
$(ALL_BUILDER_MINIMAL_IMAGES_TARGETS):
	@printf "\n\nBuilding $(VARIANT_SHORT_NAME) builder stage\n\n"
	$(call CHECK_UPDATE_IF_PROW,$(IMAGE_COMPONENT),$(AL_TAG),$(VERSIONED_VARIANT))
	$(call BUILDCTL)

$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:final-minimal-images-%=%)
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): IMAGE_TARGET=final
$(ALL_FINAL_MINIMAL_IMAGES_TARGETS): builder-minimal-images-$$(VARIANT_SHORT_NAME)
	@printf "\n\nBuilding $(VARIANT_SHORT_NAME) final stage\n\n"
	$(call BUILDCTL)

$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:packages-export-minimal-images-%=%)
# to make the file names `kind` vs `base-kind`
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): EXPORT_NAME=$(if $(and $(filter-out minimal-base,$(VARIANT)),$(filter-out minimal-base-nonroot,$(VARIANT))),$(VARIANT:minimal-base-%=%),base)
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_TARGET=export
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT_TYPE=local
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT_DIR=$(MAKE_ROOT)/../eks-distro-base-minimal-packages/$(AL_TAG)
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): IMAGE_OUTPUT=dest=$(IMAGE_OUTPUT_DIR)
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): DOCKERFILE=Dockerfile.minimal-helpers
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS):
	@printf "\n\nExporting packages and files from  $(VARIANT_SHORT_NAME) final image\n\n"
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
	@printf "\n\nValidating libraries and symlinks in $(VARIANT_SHORT_NAME) final image\n\n"
	$(call BUILDCTL)

$(ALL_TEST_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:test-minimal-images-%=%)
$(ALL_TEST_MINIMAL_IMAGES_TARGETS):
	if command -v docker &> /dev/null && docker info > /dev/null 2>&1 ; then \
		$(MAKE_ROOT)/tests/run_tests.sh $(IMAGE_REPO) $(VERSIONED_IMAGE_TAG) $(AL_TAG) $(PLATFORMS) check_$(VARIANT_SHORT_NAME) $(TEST_IMAGE_REPO); \
	fi

$(ALL_UPDATE_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:minimal-update-%=%)
$(ALL_UPDATE_MINIMAL_IMAGES_TARGETS): UPDATE_TARGET=minimal-images-$(VARIANT_SHORT_NAME)
$(ALL_UPDATE_MINIMAL_IMAGES_TARGETS): VARIANT=minimal-$(VARIANT_SHORT_NAME)
$(ALL_UPDATE_MINIMAL_IMAGES_TARGETS): IMAGE_NAME=eks-distro-$(VARIANT)
$(ALL_UPDATE_MINIMAL_IMAGES_TARGETS):
	$(call UPDATE_TARGET_BODY)

$(ALL_CREATE_PR_MINIMAL_IMAGES_TARGETS): VARIANT_SHORT_NAME=$(@:minimal-create-pr-%=%)
$(ALL_CREATE_PR_MINIMAL_IMAGES_TARGETS): IMAGE_NAME=eks-distro-$(VARIANT)
$(ALL_CREATE_PR_MINIMAL_IMAGES_TARGETS):
	$(call CREATE_PR_TARGET_BODY)

# Just to keep the buildctl commands clean/minimal, the export and validate stages never need cache info or additional build args
$(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): BUILDCTL_BUILD_ARGS=BUILT_BUILDER_IMAGE
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS): BUILDCTL_BUILD_ARGS=BUILT_BUILDER_IMAGE EXPORT_NAME
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS) $(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): BUILDCTL_IMPORT_CACHE=
$(ALL_PACKAGES_EXPORT_MINIMAL_IMAGES_TARGETS) $(ALL_VALIDATE_IMAGES_MINIMAL_TARGETS): BUILDCTL_NO_CACHE=

# These vars are all to make sure we pull the public images from ecr vs building locally
# for use when periodic does not properly update packages and we want to update them manually
.PHONY: packages-export-all-minimal-images
packages-export-all-minimal-images: IMAGE_REPO=public.ecr.aws/eks-distro-build-tooling
packages-export-all-minimal-images: VERSIONED_IMAGE_TAG=$(BUILT_IMAGE_TAG_FROM_FILE)
packages-export-all-minimal-images: $(addprefix packages-export-minimal-images-, $(MINIMAL_VARIANTS))

# These vars are all to make sure we pull the public images from ecr vs building locally
# for use to validate newly built images which have been pushed by the postsubmit
.PHONY: test-all-minimal-images
test-all-minimal-images: IMAGE_REPO=public.ecr.aws/eks-distro-build-tooling
test-all-minimal-images: VERSIONED_IMAGE_TAG=$(BUILT_IMAGE_TAG_FROM_FILE)
test-all-minimal-images: $(addprefix test-minimal-images-, $(MINIMAL_VARIANTS))

##@ Update targets
.PHONY: standard-update
standard-update: UPDATE_TARGET=standard-images
standard-update: IMAGE_NAME=eks-distro-base
standard-update: IMAGE_COMPONENT=$(IMAGE_NAME)
standard-update:
	$(call UPDATE_TARGET_BODY)

##@ PR Targets

# Update tag files in and create PR against eks-distro-build-tooling and eks-distro repos
.PHONY: standard-create-pr
standard-create-pr: IMAGE_NAME=eks-distro-base
standard-create-pr:
	$(call CREATE_PR_TARGET_BODY)

##@ Primary Targets

.PHONY: build
build: PLATFORMS=linux/amd64
build: run-make-tests buildkit-check $(IMAGE_TARGETS)

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

##@ Make tests Targets

.PHONY: run-make-tests
run-make-tests: MAKEFLAGS=
run-make-tests:
	./make-tests/make-dry-run

.PHONY: update-make-tests-expected
update-make-tests-expected:
	rm -rf make-tests/expected && mv make-tests/actual make-tests/expected  

.PHONY: var-value-%
var-value-%:
	@echo $($*)

# Temp until merge and we change prow job
.PHONY: minimal-images-base-python3.9
minimal-images-base-python3.9: minimal-images-base-python-3.9


########### DO NOT EDIT #############################
# To update call: make add-generated-help-block
# This is added to help document dynamic targets and support shell autocompletion
# Run make help for a formatted help block with all targets
include Help.mk
########### END GENERATED ###########################
