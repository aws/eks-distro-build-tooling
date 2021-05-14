REPO?=github-exporter
CLONE_URL?=https://github.com/infinityworks/$(REPO).git
GIT_COMMIT?=$(shell cat GIT_COMMIT)

ifeq ("$(CLONE_URL)","")
	$(error No clone url was provided.)
endif

ifeq ("$(REPO)","")
	$(error No repository name was provided.)
endif

ifeq ("$(GIT_COMMIT)","")
	$(error No git commit was provided.)
endif

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?=infinityworks/github-exporter
# This tag is overwritten in the prow job to point to the commit hash
IMAGE_TAG?=latest
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)

.PHONY: clone
clone: clean
	git clone $(CLONE_URL) $(REPO)
	cd $(REPO) && git checkout $(GIT_COMMIT)

.PHONY: buildkit-check
buildkit-check:
	$(MAKE_ROOT)/../../../scripts/buildkit_check.sh
	
.PHONY: local-images
local-images: clone buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--local dockerfile=./$(REPO) \
		--local context=./$(REPO) \
		--output type=oci,oci-mediatypes=true,name=$(IMAGE),dest=/tmp/github-exporter.tar

.PHONY: images
images: clone buildit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--local dockerfile=./$(REPO) \
		--local context=./$(REPO) \
		--output type=image,oci-mediatypes=true,name=$(IMAGE),push=true

.PHONY: docker
docker: clone
	docker build -t $(IMAGE) -f ./$(REPO)/Dockerfile ./$(REPO)

.PHONY: build
build: local-images

.PHONY: release
release: images

.PHONY: clean
clean:
	rm -rf $(REPO)
