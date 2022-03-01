AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_TAG?=$(shell cat IMAGE_TAG)

BASE_IMAGE_REPO?=gcr.io

BASE_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(IMAGE_TAG)
BASE_IMAGE_NAME?=k8s-prow/$(IMAGE_NAME:prow-%=%)
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

IMAGE_NAMES=prow-deck prow-clonerefs prow-crier prow-entrypoint prow-ghproxy prow-hook \
	prow-horologium prow-initupload prow-controller-manager prow-sidecar prow-sinker prow-statusreconciler prow-tide

VALUES_YAML_PATHS=deck.image utility_images.clonerefs crier.image utility_images.entrypoint ghproxy.image hook.image \
	horologium.image utility_images.initupload prowControllerManager.image utility_images.sidecar sinker.image statusreconciler.image tide.image

LOCAL_IMAGE_TARGETS=$(foreach image,$(IMAGE_NAMES),$(image)/images/amd64)
IMAGE_TARGETS=$(foreach image,$(IMAGE_NAMES),$(image)/images/push)


prow-controller-manager/images/%: BASE_IMAGE_NAME=k8s-prow/prow-controller-manager

prow-statusreconciler/images/%: BASE_IMAGE_NAME=k8s-prow/status-reconciler

prow-deck/images/%: DOCKERFILE_FOLDER?=./docker/linux/deck

.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../../../scripts/buildkit_check.sh

.PHONY: local-images
local-images: buildkit-check $(LOCAL_IMAGE_TARGETS)
	
.PHONY: images
images: buildkit-check $(IMAGE_TARGETS)	

.PHONY: update-helm-chart
update-helm-chart:
	./update_helm_images.sh "$(foreach image,$(IMAGE_NAMES),$(IMAGE_REPO)/$(image):$(IMAGE_TAG))" "$(VALUES_YAML_PATHS)"

.PHONY: build
build: local-images update-helm-chart

.PHONY: release
release: images update-helm-chart

.PHONY: all
all: release


# From Common.mk in other build tooling repos

define BUILDCTL
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(IMAGE_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=$(DOCKERFILE_FOLDER) \
		--local context=$(IMAGE_CONTEXT_DIR) \
		--opt target=$(IMAGE_TARGET) \
		--output type=$(IMAGE_OUTPUT_TYPE),oci-mediatypes=true,\"name=$(IMAGE)\",$(IMAGE_OUTPUT)	
endef 


.PHONY: %/images/push %/images/amd64 %/images/arm64
%/images/push %/images/amd64 %/images/arm64: IMAGE_NAME=$*
%/images/push %/images/amd64 %/images/arm64: DOCKERFILE_FOLDER?=./docker/linux
%/images/push %/images/amd64 %/images/arm64: IMAGE_CONTEXT_DIR?=.
%/images/push %/images/amd64 %/images/arm64: IMAGE_BUILD_ARGS?=

# Build image using buildkit for all platforms, by default pushes to registry defined in IMAGE_REPO.
%/images/push: IMAGE_PLATFORMS?=linux/amd64,linux/arm64
%/images/push: IMAGE_OUTPUT_TYPE?=image
%/images/push: IMAGE_OUTPUT?=push=true
%/images/push:
	$(BUILDCTL)

# Build image using buildkit only builds linux/amd64 oci and saves to local tar.
%/images/amd64: IMAGE_PLATFORMS?=linux/amd64

# Build image using buildkit only builds linux/arm64 oci and saves to local tar.
%/images/arm64: IMAGE_PLATFORMS?=linux/arm64

%/images/amd64 %/images/arm64: IMAGE_OUTPUT_TYPE?=oci
%/images/amd64 %/images/arm64: IMAGE_OUTPUT?=dest=/dev/null

%/images/amd64:
	$(BUILDCTL)
