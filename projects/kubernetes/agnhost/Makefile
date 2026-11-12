IMAGE_REPO?=public.ecr.aws/eks-distro-build-tooling
IMAGE_NAME?=agnhost
IMAGE_TAG?=$(shell cat IMAGE_TAG)
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

BASE_IMAGE_REPO?=registry.k8s.io/e2e-test-images
BASE_IMAGE_NAME?=agnhost
BASE_IMAGE?=$(BASE_IMAGE_REPO)/$(BASE_IMAGE_NAME):$(IMAGE_TAG)

IMAGE_PLATFORMS?=linux/amd64,linux/arm64
IMAGE_METADATA_FILE?=/tmp/$(IMAGE_NAME)-metadata.json

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../../../scripts/buildkit_check.sh

.PHONY: local-images
local-images: buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(IMAGE_PLATFORMS) \
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
		--opt platform=$(IMAGE_PLATFORMS) \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./docker/linux \
		--local context=. \
		--metadata-file $(IMAGE_METADATA_FILE) \
		--output type=image,oci-mediatypes=true,"name=$(IMAGE)",push=true
	$(MAKE_ROOT)/append_upstream_windows_manifests.sh $(IMAGE) $(BASE_IMAGE) $(IMAGE_METADATA_FILE)

.PHONY: build
build: local-images

.PHONY: release
release: images
