DEVELOPMENT?=true
AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

BASE_IMAGE?=public.ecr.aws/amazonlinux/amazonlinux:2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=eks-distro/base
# This tag is overwritten in the prow job to point to the commit hash
IMAGE_TAG?=$(shell git rev-parse HEAD | cut -c 1-8)
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

ifeq ($(DEVELOPMENT),true)
	BASE_IMAGE=amazonlinux:2
endif

.PHONY: local-images
local-images:
	# Sleep to wait for buildkitd to start up
	sleep 10
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--local dockerfile=./ \
		--local context=. \
		--output type=oci,oci-mediatypes=true,name=$(IMAGE),dest=/tmp/eks-distro-base.tar

.PHONY: images
images:
	# Sleep to wait for buildkitd to start up
	sleep 10
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64,linux/arm64 \
		--opt build-arg:BASE_IMAGE=$(BASE_IMAGE) \
		--local dockerfile=./ \
		--local context=. \
		--output type=image,oci-mediatypes=true,name=$(IMAGE),push=true

.PHONY: docker-public-login
docker-public-login:
	aws --region us-east-1 ecr-public get-authorization-token \
         --output=text \
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
		-f Dockerfile .

.PHONY: docker-push
docker-push: docker
	docker push $(IMAGE)

.PHONY: build
build: local-images

.PHONY: release
release: images
