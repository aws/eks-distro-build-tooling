GIT_VERSION?=v0.0.0-dev

AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)

BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
PROJECT_DIRECTORY:=$(BASE_DIRECTORY)/tools/eksDistroBuildToolingOpsTools

# This image build is specifically focused on a debian base image for use with EKS build systems
IMAGE_REPO?=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
PUSH_IMAGES?=true

GITHUB_EMAIL?="prow@amazonaws.com"
GITHUB_USER?="Prow Bot"

GO_ARCH:=$(shell go env GOARCH)
GO_OS:=$(shell go env GOOS)
GOLANG_VERSION:=1.20

EKS_GO_TOOLS_BINARY_NAME=eksGoTools
CONSUMER_UPDATER_BINARY_NAME=consumerUpdater
EKS_PROW_PLUGIN_BINARY_NAME=eksDistroOpsProwPlugin
EKS_DISTRO_PROW_PLUGIN_ECR_NAME=eks-distro-ops-tool

.PHONY: build-eks-go-tools
build-eks-go-tools: 
	./scripts/create_binaries.sh ${GOLANG_VERSION} ${GO_OS} ${GO_ARCH} ${GIT_VERSION} ${EKS_GO_TOOLS_BINARY_NAME}

.PHONY: build-consumerUpdater
build-consumerUpdater: unit-test lint
	./scripts/create_binaries.sh ${GOLANG_VERSION} ${GO_OS} ${GO_ARCH} ${GIT_VERSION} ${CONSUMER_UPDATER_BINARY_NAME}

.PHONY: build-binary-eksDistroOpsProwPlugin
build-binary-eksDistroOpsProwPlugin:  
	./scripts/create_binaries.sh ${GOLANG_VERSION} ${GO_OS} ${GO_ARCH} ${GIT_VERSION} ${EKS_PROW_PLUGIN_BINARY_NAME}

.PHONY: build-eksDistroOpsProwPlugin
build-eksDistroOpsProwPlugin: build-binary-eksDistroOpsProwPlugin local-images-eksDistroOpsProwPlugin

.PHONY: release-eksDistroOpsProwPlugin
release-eksDistroOpsProwPlugin: build-binary-eksDistroOpsProwPlugin images-eksDistroOpsProwPlugin
	
.PHONY: unit-test
unit-test:
	go test -v ./... --cover

.PHONY: lint
lint: bin/golangci-lint ## Run golangci-lint
	bin/golangci-lint run

bin/golangci-lint: ## Download golangci-lint
bin/golangci-lint: GOLANGCI_LINT_VERSION?=v1.54.2
bin/golangci-lint:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s $(GOLANGCI_LINT_VERSION)

.PHONY: clean
clean:
	rm -rf ./bin

.PHONY: mocks
mocks: ## Generate mocks
	go get github.com/golang/mock/mockgen@v1.6.0
	${GOPATH}/bin/mockgen -destination=pkg/github/mocks/github.go -package=mocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github" GitClient,IssueClient,RepoClient,PullRequestClient
	${GOPATH}/bin/mockgen -destination=pkg/consumerUpdater/mocks/consumerUpdater.go -package=mocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/consumerUpdater" Consumer,Updater,Notifier
	${GOPATH}/bin/mockgen -destination=pkg/dependencyUpdater/mocks/dependencyUpdater.go -package=mocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/dependencyUpdater" Dependency,Updater
	${GOPATH}/bin/mockgen -destination=pkg/git/mocks/git.go -package=mocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git" Client,GoGit


.PHONY: local-images-eksDistroOpsProwPlugin
local-images-eksDistroOpsProwPlugin: PUSH_IMAGES=false
local-images-eksDistroOpsProwPlugin: images-eksDistroOpsProwPlugin

.PHONY: images-eksDistroOpsProwPlugin
images-eksDistroOpsProwPlugin: buildkit-check
images-eksDistroOpsProwPlugin: IMAGE_NAME=$(EKS_DISTRO_PROW_PLUGIN_ECR_NAME)
images-eksDistroOpsProwPlugin: IMAGE_BUILD_ID=$(shell cat $(PROJECT_DIRECTORY)/EKS_DISTRO_PROW_PLUGIN_RELEASE)
images-eksDistroOpsProwPlugin: IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_BUILD_ID)
images-eksDistroOpsProwPlugin: BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE)\",push=$(PUSH_IMAGES)
images-eksDistroOpsProwPlugin:
	$(BASE_DIRECTORY)/scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(GO_OS)/$(GO_ARCH) \
		--local dockerfile=$(PROJECT_DIRECTORY)/docker \
		--local context=$(PROJECT_DIRECTORY) \
		--progress plain \
		--opt build-arg:BINARY_OUTPUT_PATH=bin/$(GO_OS)/$(GO_ARCH)/$(EKS_PROW_PLUGIN_BINARY_NAME) \
		--opt build-arg:BINARY_NAME=$(EKS_PROW_PLUGIN_BINARY_NAME) \
		--output $(BUILDKIT_OUTPUT)

.PHONY: buildkit-check
buildkit-check:
	$(BASE_DIRECTORY)/scripts/buildkit_check.sh
