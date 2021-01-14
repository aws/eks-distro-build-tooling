REPO?="https://github.com/gomods/athens.git"
CHART_ROOT?= $(shell git rev-parse --show-toplevel)/projects/gomods/athens
CHART_BUCKET?="prowdataclusterstack-316-prowchartsbucket2e50b8d9-8b0f36hrcee8"
AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2

MAKE_ROOT=$(shell cd "$(shell dirname "${BASH_SOURCE[0]}")" && pwd -P)
BASE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
BASE_IMAGE_NAME?=eks-distro/base
BASE_TAG?=$(shell cat $(MAKE_ROOT)/../../../EKS_DISTRO_BASE_TAG_FILE)
BASE_IMAGE?=$(BASE_REPO)/$(BASE_IMAGE_NAME):$(BASE_TAG)

IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME?="gomods/athens"
IMAGE_TAG?="latest"
IMAGE?=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: build
build:
	${CHART_ROOT}/upload-athens-artifacts.sh ${REPO} ${CHART_BUCKET} ${BASE_IMAGE} ${IMAGE} "false"

.PHONY: release
release:
	${CHART_ROOT}/upload-athens-artifacts.sh ${REPO} ${CHART_BUCKET} ${BASE_IMAGE} ${IMAGE} "true"

.PHONY: clean
clean:
	rm -rf ${CHART_ROOT}/build/
