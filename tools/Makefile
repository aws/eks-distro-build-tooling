GIT_VERSION?=v0.0.0-dev

GO_ARCH:=$(shell go env GOARCH)
GO_OS:=$(shell go env GOOS)

EKS_GO_TOOLS_BINARY_NAME="eksGoTools"
SLIM_JIM_BINARY_NAME="slim-jim"

.PHONY: build-eks-go-tools
build-eks-go-tools:  unit-test lint
	CGO_ENABLED=0 GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build -ldflags "-X github.com/aws/eks-distro-build-tooling/tools/pkg/version.gitVersion=$(GIT_VERSION) -s -w -extldflags -static" -o bin/$(GO_OS)/$(GO_ARCH)/$(EKS_GO_TOOLS_BINARY_NAME) github.com/aws/eks-distro-build-tooling/tools/cmd/eksGoTool


.PHONY: build-slim-jim
build-slim-jim:  unit-test lint
	CGO_ENABLED=0 GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build -ldflags "-X github.com/aws/eks-distro-build-tooling/tools/pkg/version.gitVersion=$(GIT_VERSION) -s -w -extldflags -static" -o bin/$(GO_OS)/$(GO_ARCH)/$(SLIM_JIM_BINARY_NAME) github.com/aws/eks-distro-build-tooling/tools/cmd/slim-jim

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
