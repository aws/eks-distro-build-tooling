GIT_VERSION?=v0.0.0-dev
IMAGE_BUILD_ID=$(shell cat ./EKS_DISTRO_PROW_PLUGIN_RELEASE)

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

EKS_GO_TOOLS_BINARY_NAME="eksGoTools"
EKS_PROW_PLUGIN_BINARY_NAME="eksDistroOpsProwPlugin"

.PHONY: build-eks-go-tools
build-eks-go-tools:
	CGO_ENABLED=0 GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build -ldflags "-X github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/version.gitVersion=$(GIT_VERSION) -s -w -extldflags -static" -o bin/$(GO_OS)/$(GO_ARCH)/$(EKS_GO_TOOLS_BINARY_NAME) github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/cmd/eksGoTool

.PHONY: build-prowPlugin
build-prowPlugin: 
	CGO_ENABLED=0 GOOS=linux GOARCH=$(GO_ARCH) go build -ldflags "-X github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/version.gitVersion=$(GIT_VERSION) -s -w -extldflags -static" -o bin/$(GO_OS)/$(GO_ARCH)/$(EKS_PROW_PLUGIN_BINARY_NAME) github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/cmd/$(EKS_PROW_PLUGIN_BINARY_NAME)

.PHONY: images-eksDistroOpsProwPlugin
images-eksDistroOpsProwPlugin: unit-test build-prowPlugin local-images-eksProwPlugin

.PHONY: unit-test
unit-test:
	go test -v ./... --cover

.PHONY: lint
lint: bin/golangci-lint ## Run golangci-lint
	bin/golangci-lint run

bin/golangci-lint: ## Download golangci-lint
bin/golangci-lint: GOLANGCI_LINT_VERSION?=v1.50.1
bin/golangci-lint:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s $(GOLANGCI_LINT_VERSION)

.PHONY: clean
clean:
	rm -rf ./bin

.PHONY: mocks
mocks: ## Generate mocks
	go get github.com/golang/mock/mockgen@v1.6.0
	${GOPATH}/bin/mockgen -destination=pkg/github/mocks/github.go -package=mocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github" GitClient,IssueClient,RepoClient,PullRequestClient

.PHONY: local-images-eksProwPlugin
local-images-eksProwPlugin: PUSH_IMAGE=false
local-images-eksProwPlugin: images-eksProwPlugin

.PHONY: images-eksProwPlugin
images-eksProwPlugin: buildkit-check
images-eksProwPlugin: IMAGE_NAME=$(EKS_PROW_PLUGIN_BINARY_NAME)
images-eksProwPlugin: IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_BUILD_ID)
images-eksProwPlugin: BUILDKIT_OUTPUT=type=image,oci-mediatypes=true,\"name=$(IMAGE)\",push=$(PUSH_IMAGES)
images-eksProwPlugin:
	$(BASE_DIRECTORY)/scripts/buildkit.sh \
		build \
		--frontend dockerfile.v0 \
		--opt platform=$(GO_OS)/$(GO_ARCH) \
		--local dockerfile=$(PROJECT_DIRECTORY)/docker \
		--local context=$(PROJECT_DIRECTORY) \
		--progress plain \
		--opt build-arg:BINARY_OUTPUT_PATH=bin/$(GO_OS)/$(GO_ARCH)/eksDistroOpsProwPlugin \
		--output $(BUILDKIT_OUTPUT)

.PHONY: buildkit-check
buildkit-check:
	$(BASE_DIRECTORY)/scripts/buildkit_check.sh
