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

AL_TAG?=2023
LATEST?=$(VARIANT)-latest.al23

IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(VARIANT)-$(IMAGE_TAG)

LATEST_TAGS=$(foreach tag,$(LATEST),$(IMAGE_REPO)/$(IMAGE_NAME):$(tag))
LATEST_IMAGE=$(shell echo $(LATEST_TAGS) | sed "s/ \+/,/g")

PRIVATE_IMAGE_REPO?=
PRIVATE_IMAGE=$(if $(PRIVATE_IMAGE_REPO),$(PRIVATE_IMAGE_REPO)/$(IMAGE_NAME):$(VARIANT)-$(IMAGE_TAG),)
IMAGE_NAMES=$(IMAGE),$(LATEST_IMAGE)$(if $(PRIVATE_IMAGE),$(COMMA)$(PRIVATE_IMAGE),)

BASE_IMAGE_REPO?=public.ecr.aws/eks-distro-build-tooling
BASE_IMAGE_NAME?=eks-distro-minimal-base-kind
BASE_IMAGE?=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(call BASE_TAG_FROM_TAG_FILE,$(BASE_IMAGE_NAME))
# using the minimal-base-builder as the base for the download/gcc stages of
# this build since it doesnt change too often, limiting churn/rebuilds
BUILDER_IMAGE_NAME?=eks-distro-minimal-base
BUILDER_IMAGE?=$(BASE_IMAGE_REPO)/$(BUILDER_IMAGE_NAME)-builder:$(call BASE_TAG_FROM_TAG_FILE,$(BUILDER_IMAGE_NAME))
UPDATE_BASE_IMAGE?=true

IMPORT_CACHE_REPOS=public.ecr.aws/eks-distro-build-tooling $(IMAGE_REPO)

BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE_NAMES)\",push=true
BUILDKIT_PLATFORMS?=linux/amd64,linux/arm64
FINAL_STAGE_BASE?=full-copy-stage
VARIANT?=standard
IGNORE_NO_CACHE?=false

NETRC=--secret id=netrc,src=$(HOME)/.netrc
COMMA=,
EMPTY=
SPACE=$(EMPTY) $(EMPTY)

define BASE_TAG_FROM_TAG_FILE
$(shell yq e ".al$(AL_TAG).\"$(1)\"" $(MAKE_ROOT)/../EKS_DISTRO_TAG_FILE.yaml)
endef

define NEWLINE


endef

REALPATH=TZ=utc $(shell if [ "$$(uname -s)" = "Darwin" ] && command -v grealpath &> /dev/null; then echo grealpath; else echo realpath; fi)

GOLANG_RPM_OUTPUT_DIR?=$(MAKE_ROOT)/tmp/golang-downloads
GOLANG_VERSIONS_YAML?=$(MAKE_ROOT)/../eks-distro-base/golang_versions.yaml
GOLANG_DEFAULT_MINOR?=$(shell yq e '.GOLANG_DEFAULT_MINOR' ${MAKE_ROOT}/versions.yaml)
GOLANG_VARIANTS?=$(shell yq e '.golang.variants[]' $(GOLANG_VERSIONS_YAML))
GOLANG_EXTRA_VARIANTS=$(filter-out $(GOLANG_DEFAULT_MINOR),$(GOLANG_VARIANTS))
GOLANG_FULL_VERSION=$(shell yq e '.golang.versions["GOLANG_$(1)_FULL_VERSION"] // ""' $(GOLANG_VERSIONS_YAML))
GOLANG_FULL_VERSIONS=$(strip $(foreach variant,$(1),$(call GOLANG_FULL_VERSION,$(variant))))
GOLANG_VERSIONS?=$(subst $(SPACE),$(COMMA),$(call GOLANG_FULL_VERSIONS,$(GOLANG_VARIANTS)))
GOLANG_DEFAULT_VERSION?=$(if $(filter $(GOLANG_DEFAULT_MINOR),$(GOLANG_VARIANTS)),$(call GOLANG_FULL_VERSION,$(GOLANG_DEFAULT_MINOR)),)
GOLANG_EXTRA_VERSIONS?=$(subst $(SPACE),$(COMMA),$(call GOLANG_FULL_VERSIONS,$(GOLANG_EXTRA_VARIANTS)))
GOLANG_VERSION_KEY_COUNT?=$(shell yq e '.golang.versions | length' $(GOLANG_VERSIONS_YAML))
GOLANG_RPM_DOWNLOAD_TARGETS?=$(addprefix download-golang-,$(call GOLANG_FULL_VERSIONS,$(GOLANG_VARIANTS)))

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
images-%:
	$(eval $(subst #,$(NEWLINE),$(shell yq  e 'to_entries | .[] | [.key,.value] | join("=") ' versions.yaml | tr '\n' '#')))
	$(eval IMAGE_BUILD_ARGS=$(shell yq  e 'to_entries | .[] | .key ' versions.yaml))
	$(MAKE_ROOT)/../scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(BUILDKIT_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--opt build-arg:GOPROXY=$(GOPROXY) \
		--opt build-arg:FINAL_STAGE_BASE=$(FINAL_STAGE_BASE) \
		--opt build-arg:GOLANG_RPM_SOURCE_DIR=$(shell $(REALPATH) --relative-to $(MAKE_ROOT) $(GOLANG_RPM_OUTPUT_DIR)) \
		--opt build-arg:GOLANG_VERSIONS=$(GOLANG_VERSIONS) \
		--opt build-arg:GOLANG_EXTRA_VERSIONS=$(GOLANG_EXTRA_VERSIONS) \
		--opt build-arg:GOLANG_DEFAULT_VERSION=$(GOLANG_DEFAULT_VERSION) \
		$(foreach BUILD_ARG,$(IMAGE_BUILD_ARGS),--opt build-arg:$(BUILD_ARG)=$($(BUILD_ARG))) \
		--export-cache type=inline \
		$(foreach repo,$(IMPORT_CACHE_REPOS),--import-cache type=registry,ref=$(repo)/builder-base:$(word 1,$(LATEST))) \
		$(if $(filter false,$(IGNORE_NO_CACHE)),--opt no-cache=final,) \
		--local dockerfile=./ \
		--local context=$(MAKE_ROOT) \
		$(if $(wildcard $(HOME)/.netrc),$(NETRC),) \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)
	$(if $(findstring push=true,$(BUILDKIT_OUTPUT)),$(MAKE_ROOT)/../scripts/tag_image_children.sh $(IMAGE)$(COMMA)$(LATEST_IMAGE),)
	$(if $(and $(PRIVATE_IMAGE),$(findstring push=true,$(BUILDKIT_OUTPUT))),$(MAKE_ROOT)/../scripts/tag_image_children.sh $(PRIVATE_IMAGE) || echo "WARNING: failed to tag child images for $(PRIVATE_IMAGE)",)
	if [ "$(VARIANT)" = "standard" ] && [ "$(UPDATE_BASE_IMAGE)" = "true" ]; then \
		./update_base_image.sh $(IMAGE_TAG); \
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
build: validate-shasums copy-generate-attribution download-golang local-images remove-generate-attribution

.PHONY: release
release: validate-shasums copy-generate-attribution download-golang images remove-generate-attribution

.PHONY: all
all: release

.PHONY: update-shasums
update-shasums:
	./scripts/update_shasums.sh >/dev/null 2>&1

.PHONY: validate-shasums
validate-shasums: update-shasums
	git diff --exit-code ./checksums

.PHONY: download-golang
download-golang: $(GOLANG_RPM_DOWNLOAD_TARGETS)
	@if [ -z "$(GOLANG_DEFAULT_VERSION)" ]; then \
		echo "GOLANG_DEFAULT_MINOR $(GOLANG_DEFAULT_MINOR) is not in $(GOLANG_VERSIONS_YAML)"; \
		exit 1; \
	fi
	@if [ "$(words $(GOLANG_VARIANTS))" != "$(GOLANG_VERSION_KEY_COUNT)" ] || \
		[ "$(words $(call GOLANG_FULL_VERSIONS,$(GOLANG_VARIANTS)))" != "$(words $(GOLANG_VARIANTS))" ]; then \
		echo "golang.variants and golang.versions in $(GOLANG_VERSIONS_YAML) do not match"; \
		exit 1; \
	fi

.PHONY: clean-golang-download
clean-golang-download:
	rm -f ${GOLANG_RPM_OUTPUT_DIR}/golang-*.rpm

.PHONY: download-golang-%
download-golang-%:
	mkdir -p ${GOLANG_RPM_OUTPUT_DIR}
	${MAKE_ROOT}/scripts/download_golang.sh ${*} ${GOLANG_RPM_OUTPUT_DIR}$(if $(filter $*,$(GOLANG_DEFAULT_VERSION)),,/extra) ${BUILDKIT_PLATFORMS}

.PHONY: check-golang-release
check-golang-release:
	${MAKE_ROOT}/scripts/check_upstream_golang.sh
