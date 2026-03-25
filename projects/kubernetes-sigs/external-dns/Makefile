IMAGE_REPO?=public.ecr.aws/eks-distro-build-tooling
IMAGE_NAME?=external-dns
IMAGE_TAG?=$(shell cat IMAGE_TAG)
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

BASE_IMAGE_TAG?=$(shell cat IMAGE_TAG)
BASE_IMAGE_REPO?=registry.k8s.io/external-dns
BASE_IMAGE_NAME?=external-dns
BASE_IMAGE?=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(BASE_IMAGE_TAG)

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../../../scripts/buildkit_check.sh

.PHONY: local-images
local-images: buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./docker/linux \
		--local context=. \
		--output type=oci,oci-mediatypes=true,"name=$(IMAGE)",dest=/dev/null

.PHONY: images
images: buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./docker/linux \
		--local context=. \
		--output type=image,oci-mediatypes=true,"name=$(IMAGE)",push=true

.PHONY: build
build: local-images

.PHONY: release
release: images
