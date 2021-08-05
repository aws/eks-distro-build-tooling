SHELL := /bin/bash

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

BASE_IMAGE?=public.ecr.aws/amazonlinux/amazonlinux:2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=eks-distro-base
IMAGE_TAG?=$(shell date "+%F-%s")
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
IMAGE_TARGET=base

DOCKERFILE?=Dockerfile

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

MINIMAL_VARIANTS=base base-nonroot base-iptables
LOCAL_IMAGE_TARGETS=base-local-images $(addprefix minimal-local-images-, $(MINIMAL_VARIANTS))
IMAGE_TARGETS=base-images $(addprefix minimal-images-, $(MINIMAL_VARIANTS))
UPDATE_TARGETS=base-update $(addprefix minimal-update-, $(MINIMAL_VARIANTS))
CREATE_PR_TARGETS=base-create-pr $(addprefix minimal-create-pr-, $(MINIMAL_VARIANTS))

ifeq ("$(REPO_OWNER)","")
    $(error No org information was provided, please set and export REPO_OWNER environment variable. \
      This is used to raise a pull request against your org after updating tags in the respective files.)
endif


## --------------------------------------
## Help
## --------------------------------------
##@ Helpers
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../scripts/buildkit_check.sh

.PHONY: local-images-%
local-images-%: buildkit-check
	 ./check_update.sh $(IMAGE_NAME) 
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt filename=$(DOCKERFILE) \
		--opt platform=linux/amd64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./ \
		--local context=. \
		--opt target=$(IMAGE_TARGET) \
		--output type=oci,oci-mediatypes=true,name=$(IMAGE),dest=/tmp/$(IMAGE_NAME).tar

.PHONY: images-%
images-%: buildkit-check
	if [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./check_update.sh $(IMAGE_NAME) ; \
	fi
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt filename=$(DOCKERFILE) \
		--opt platform=linux/amd64,linux/arm64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--progress plain \
		--local dockerfile=./ \
		--local context=. \
		--opt target=$(IMAGE_TARGET) \
		--output type=image,oci-mediatypes=true,name=$(IMAGE),push=true

.PHONY: base-%
base-%: %-base
	$(MAKE) $*-base

.PHONY: minimal-local-images-%
minimal-local-images-%:
	$(MAKE) local-images-minimal-$* IMAGE_NAME=eks-distro-minimal-$* DOCKERFILE=Dockerfile.minimal IMAGE_TARGET=$*

.PHONY: minimal-images-%
minimal-images-%:
	$(MAKE) images-minimal-$* IMAGE_NAME=eks-distro-minimal-$* DOCKERFILE=Dockerfile.minimal IMAGE_TARGET=$*


.PHONY: docker-public-login
docker-public-login:
	aws --region us-east-1 ecr-public get-authorization-token --output=text \
	 --query 'authorizationData.authorizationToken' |  \
	 base64 --decode | cut -d: -f2 | \
	 docker login -u AWS --password-stdin https://public.ecr.aws

.PHONY: public-images
public-images: docker-public-login
	$(eval REPOSITORY=$(shell aws --region us-east-1 ecr-public describe-registries --query 'registries[*].registryUri' --output text))
	$(eval IMAGE=$(REPOSITORY)/$(IMAGE_NAME):$(IMAGE_TAG))
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt filename=$(DOCKERFILE) \
		--opt platform=linux/amd64,linux/arm64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--local dockerfile=./ \
		--local context=. \
		--output type=image,oci-mediatypes=true,name=$(IMAGE),push=true

# for local development only
.PHONY: ecr
ecr:
	aws ecr create-repository \
		--repository-name $(IMAGE_NAME) \
		--image-tag-mutability IMMUTABLE \
		--image-scanning-configuration  scanOnPush=true || true

.PHONY: docker
docker:
	docker build \
		-t $(IMAGE) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg TARGETARCH=amd64 \
		--build-arg TARGETOS=linux \
		-f $(DOCKERFILE) .

.PHONY: docker-push
docker-push: docker
	docker push $(IMAGE)

.PHONY: build
build: $(LOCAL_IMAGE_TARGETS)

.PHONY: release
release: $(IMAGE_TARGETS)


.PHONY: update-%
update-%:
	echo "false" > $(MAKE_ROOT)/$(IMAGE_NAME)-pushed
	$(eval RETURN_MESSAGE="$(shell ./check_update.sh $(IMAGE_NAME) )")
	if [ $(RETURN_MESSAGE) = "Updates required" ]; then \
		source $(MAKE_ROOT)/../scripts/setup_public_ecr_push.sh && $(MAKE) images-$*; \
		echo "true" > $(MAKE_ROOT)/$(IMAGE_NAME)-pushed; \
	elif [ $(RETURN_MESSAGE) = "Error" ]; then \
		exit 1; \
	fi

.PHONY: base-update
base-update:
	$(MAKE) update-base

.PHONY: minimal-update-%
minimal-update-%:
	$(MAKE) update-$* IMAGE_NAME=eks-distro-minimal-$* DOCKERFILE=Dockerfile.minimal IMAGE_TARGET=$*

# Update tag files in and create PR against eks-distro-build-tooling and eks-distro repos
.PHONY: create-pr-%
create-pr-%:
	if [ "$(JOB_TYPE)" = "presubmit" ] || [ "$(JOB_TYPE)" = "postsubmit" ]; then \
		./update_base_image.sh $(IMAGE_TAG) $(IMAGE_NAME); \
	elif [ "$(shell cat $(MAKE_ROOT)/$(IMAGE_NAME)-pushed)" = "true" ]; then \
		./update_base_image.sh $(IMAGE_TAG) $(IMAGE_NAME); \
	fi

.PHONY: base-create-pr
base-create-pr:
	$(MAKE) create-pr-base

.PHONY: minimal-create-pr-%
minimal-create-pr-%:
	$(MAKE) create-pr-$* IMAGE_NAME=eks-distro-minimal-$*

.PHONY: create-pr
create-pr: $(CREATE_PR_TARGETS)
	$(shell $(MAKE_ROOT)/../pr-scripts/create_pr.sh eks-distro 'unused' 'unused' 'EKS_DISTRO*_TAG_FILE')
	$(shell $(MAKE_ROOT)/../pr-scripts/create_pr.sh eks-distro-build-tooling 'unused' 'unused' 'EKS_DISTRO*_TAG_FILE')

.PHONY: update
update: buildkit-check $(UPDATE_TARGETS)


.PHONY: all
all: release

## --------------------------------------
## Document dynamic build targets
## --------------------------------------
base-local-images: ## Build standard full base image
minimal-local-images-base: ## Build minimal base image with base-system/ca-certs/user/nsswitch
minimal-local-images-base-nonroot: ## Build minimal base image nonroot variant
minimal-local-images-base-iptables: ## Build minimal base image with iptables + glibc

base-images: ## Build and push standard full base image
minimal-images-base: ## Build and push minimal base image with base-system/ca-certs/user/nsswitch
minimal-images-base-nonroot: ## Build and push minimal base image nonroot variant
minimal-images-base-iptables: ## Build and push minimal base image with iptables + glibc

base-update:  ## Check for out of date packages on standard full base image and push new
minimal-base-update: ## Check for out of date packages on minimal base image and push new
minimal-base-nonroot-update: ## Check for out of date packages on minimal nonroot base image and push new
minimal-base-iptables-update: ## Check for out of date packages on minimal iptables base image and push new

base-create-pr:  ## Update standard base image tag if pushed
minimal-base-create-pr: ## Update minimal base image tag if pushed
minimal-base-nonroot-create-pr: ## Update minimal base nonroot image tag if pushed
minimal-base-iptables-create-pr: ## Update minimal base iptables image tag if pushed
