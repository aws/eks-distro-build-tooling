AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

BASE_IMAGE?=public.ecr.aws/amazonlinux/amazonlinux:2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=builder-base
# This tag is overwritten in the prow job to point to the PR branch commit hash (presubmit)
# or the base branch commit hash (postsubmit)
IMAGE_TAG?=latest
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
LATEST_IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):latest

BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE),$(LATEST_IMAGE)\",push=true
BUILDKIT_PLATFORMS=linux/amd64,linux/arm64

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

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
local-images: BUILDKIT_OUTPUT=type=tar,dest=/tmp/builder-base.tar
#local-images: BUILDKIT_PLATFORMS=linux/amd64
local-images: images
	
.PHONY: images
images: buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(BUILDKIT_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--opt build-arg:GOPROXY=$(GOPROXY) \
		--local dockerfile=./ \
		--local context=. \
		--progress plain \
		--output $(BUILDKIT_OUTPUT)
	./update_base_image.sh

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
build: copy-generate-attribution local-images remove-generate-attribution

.PHONY: release
release: copy-generate-attribution images remove-generate-attribution

.PHONY: all
all: release
