AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_TAG?=$(shell cat IMAGE_TAG)

BASE_IMAGE_REPO?=gcr.io
BASE_IMAGE_NAME?=k8s-prow/deck
BASE_IMAGE=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(IMAGE_TAG)

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=prow-deck
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,name=$(IMAGE),push=true
BUILDKIT_PLATFORMS=linux/amd64,linux/arm64

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../../../scripts/buildkit_check.sh

.PHONY: local-images
local-images: BUILDKIT_OUTPUT=type=tar,dest=/tmp/prow-deck.tar
local-images: BUILDKIT_PLATFORMS=linux/amd64
local-images: images
	
.PHONY: images
images: buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(BUILDKIT_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--local dockerfile=./docker/linux \
		--local context=. \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)
	./update_deck_image.sh $(IMAGE)

.PHONY: build
build: local-images

.PHONY: release
release: images

.PHONY: all
all: release
