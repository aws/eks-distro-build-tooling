BIN_DIR ?= bin
GO ?= go

all: fmt vet check

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

build: $(BIN_DIR)
	CGO_ENABLED=0 $(GO) build -ldflags='-s -w -extldflags="-static" -buildid=""' -trimpath -o $(BIN_DIR)/iptables-wrapper github.com/kubernetes-sigs/iptables-wrappers

vet: ## Run go vet against code.
	$(GO) vet ./...

fmt: ## Check formatting
	if [ "$$(gofmt -e -l . | tee /dev/tty | wc -l)" -gt 0 ]; then \
		echo "Go files need formatting"; \
    	exit 1; \
	fi

build-tests: $(BIN_DIR)
	$(GO) test ./test -c -o $(BIN_DIR)/tests

check: check-debian check-debian-nosanity check-debian-backports check-fedora check-alpine

check-debian: build build-tests
	./test/run-test.sh --build-fail debian

check-debian-nosanity: build build-tests
	./test/run-test.sh --build-arg="INSTALL_ARGS=--no-sanity-check" --nft-fail debian-nosanity

check-debian-backports: build build-tests
	./test/run-test.sh --build-arg="REPO=buster-backports" debian-backports

check-fedora: build build-tests
	./test/run-test.sh fedora

check-alpine: build build-tests
	./test/run-test.sh alpine

check-distroless: build build-tests
	./test/run-test.sh distroless
