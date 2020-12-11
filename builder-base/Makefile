DEVELOPMENT?=true
AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

BASE_REPO?=137112412989.dkr.ecr.$(AWS_REGION).amazonaws.com
BASE_IMAGE_NAME?=amazonlinux
BASE_TAG?=2
BASE_IMAGE?=$(BASE_REPO)/$(BASE_IMAGE_NAME):$(BASE_TAG)

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=eks-distro/builder
# This tag is overwritten in the prow job to point to the commit hash
IMAGE_TAG?=latest
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

GOLANG_DOWNLOAD_URL=https://golang.org/dl
GOLANG_VERSION=1.15.5
GOLANG_CHECKSUM=9a58494e8da722c3aef248c9227b0e9c528c7318309827780f16220998180a0d
BUILDKIT_VERSION=v0.7.2
BUILDKIT_CHECKSUM=33bcaa49b31bc3a277ac75d32fce3f5442d39f53a1799b8624e985279b579f74

ifeq ($(DEVELOPMENT),true)
	BASE_IMAGE=amazonlinux:2
endif

.PHONY: local-images
local-images:
	mkdir -p /tmp/builder-base
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:GOLANG_DOWNLOAD_URL=$(GOLANG_DOWNLOAD_URL) \
		--opt build-arg:GOLANG_VERSION=$(GOLANG_VERSION) \
		--opt build-arg:GOLANG_CHECKSUM=$(GOLANG_CHECKSUM) \
		--opt build-arg:BUILDKIT_VERSION=$(BUILDKIT_VERSION) \
		--opt build-arg:BUILDKIT_CHECKSUM=$(BUILDKIT_CHECKSUM) \
		--local dockerfile=./ \
		--local context=. \
		--output type=tar,dest=/tmp/builder-base/output.tar

.PHONY: images
images:
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:GOLANG_DOWNLOAD_URL=$(GOLANG_DOWNLOAD_URL) \
		--opt build-arg:GOLANG_VERSION=$(GOLANG_VERSION) \
		--opt build-arg:GOLANG_CHECKSUM=$(GOLANG_CHECKSUM) \
		--opt build-arg:BUILDKIT_VERSION=$(BUILDKIT_VERSION) \
		--opt build-arg:BUILDKIT_CHECKSUM=$(BUILDKIT_CHECKSUM) \
		--local dockerfile=./ \
		--local context=. \
		--output type=image,oci-mediatypes=true,name=$(IMAGE),push=true

# for local development only
docker:
	docker build \
		-t $(IMAGE) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg TARGETARCH=amd64 \
		--build-arg TARGETOS=linux \
		--build-arg GOLANG_DOWNLOAD_URL=$(GOLANG_DOWNLOAD_URL) \
		--build-arg GOLANG_VERSION=$(GOLANG_VERSION) \
		--build-arg GOLANG_CHECKSUM=$(GOLANG_CHECKSUM) \
		--build-arg BUILDKIT_VERSION=$(BUILDKIT_VERSION) \
		--build-arg BUILDKIT_CHECKSUM=$(BUILDKIT_CHECKSUM) \
		-f Dockerfile .

.PHONY: build
build: local-images

.PHONY: release
release: images
