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
		-f Dockerfile .

.PHONY: build
build: local-images

.PHONY: release
release: images
