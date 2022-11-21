GIT_VERSION?=v0.0.0-dev

GO_ARCH:=$(shell go env GOARCH)
GO_OS:=$(shell go env GOOS)

MINIMAL_IMAGE_BUILD_TOOL_BINARY_NAME="minimalImageBuildTool"

.PHONY: build-minimal-image-build-tool
build-eks-go-tools:  unit-test lint
	CGO_ENABLED=0 GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build -ldflags "-X github.com/aws/eks-distro-build-tooling/tools/minimalImageBuildTool/pkg/version.gitVersion=$(GIT_VERSION) -s -w -extldflags -static" -o bin/$(GO_OS)/$(GO_ARCH)/$(MINIMAL_IMAGE_BUILD_TOOL_BINARY_NAME) github.com/aws/eks-distro-build-tooling/tools/minimalImageBuildTool/cmd/minimalImageBuild

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
	${GOPATH}/bin/mockgen -destination=pkg/github/mocks/github.go -package=mocks "github.com/aws/eks-distro-build-tooling/tools/minimalImageBuildTool/pkg/github" GitClient,IssueClient,RepoClient,PullRequestClient
