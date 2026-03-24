AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_TAG?=$(shell cat IMAGE_TAG)

BASE_IMAGE_REPO?=docker.io/tonistiigi
BASE_IMAGE_NAME?=binfmt
BASE_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(IMAGE_TAG)

IMAGE_NAME?=binfmt-misc
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

IMAGE_PLATFORMS?=linux/amd64,linux/arm64

.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../../../scripts/buildkit_check.sh

.PHONY: local-images
local-images: buildkit-check
	$(BUILDCTL_LOCAL)

.PHONY: images
images: buildkit-check
	$(BUILDCTL_PUSH)

.PHONY: build
build: local-images

.PHONY: release
release: images

define BUILDCTL_LOCAL
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(IMAGE_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./docker/linux \
		--local context=. \
		--output type=oci,oci-mediatypes=true,\"name=$(IMAGE)\",dest=/dev/null
endef

define BUILDCTL_PUSH
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(IMAGE_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./docker/linux \
		--local context=. \
		--output type=image,oci-mediatypes=true,\"name=$(IMAGE)\",push=true
endef
