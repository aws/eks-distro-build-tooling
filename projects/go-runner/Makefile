RELEASE_BRANCH?=0.18.0
BASE_DIRECTORY:=$(shell git rev-parse --show-toplevel)
GIT_TAG?=$(shell cat ./$(RELEASE_BRANCH)/GIT_TAG)
GO_SOURCE_VERSION?=$(shell cat ./$(RELEASE_BRANCH)/GOLANG_VERSION)
GO_VERSION_DIRECTORY:=$(BASE_DIRECTORY)/projects/golang/go/$(GO_SOURCE_VERSION)
GOPATH:=$(GO_VERSION_DIRECTORY)/archives/linux/amd64/go

# Variables used in the using upstream binarys in the golang-debian image
BUILDER_BASE_VERSIONS_YAML=$(BASE_DIRECTORY)/builder-base/versions.yaml
BUILDER_BASE_GO_VERSION=$(shell grep -E "^GOLANG_VERSION_$(subst .,,$(GO_SOURCE_VERSION))" $(BUILDER_BASE_VERSIONS_YAML))
GO_BIN_VERSION_WITH_RELEASE=$(subst GOLANG_VERSION_$(subst .,,$(GO_SOURCE_VERSION)): ,,$(BUILDER_BASE_GO_VERSION))
GO_BIN_VERSION_WITHOUT_RELEASE=go$(shell [[ $(GO_BIN_VERSION_WITH_RELEASE) =~ [0-9]+.[0-9]+.[0-9]+ ]] && echo $${BASH_REMATCH[0]})

REPO=release-src
REPO_OWNER=kubernetes
# REPO can't be release since there is a phony release target
# using release-src and overriding component
COMPONENT=$(REPO_OWNER)/release
CLONE_URL=https://github.com/$(COMPONENT).git

GO_RUNNER_IMAGE_COMPONENT?=kubernetes/go-runner
IMAGE_NAMES=go-runner

BINARY_TARGET_FILES=go-runner
GO_MOD_PATHS=images/build/go-runner
# create default attribution name and save licenses in default _output/attribution folder instead
# of with go-runner prefix
GO_RUNNER_ATTRIBUTION_OVERRIDE=

DOCKERFILE_FOLDER=./docker/$(IMAGE_NAME)
GOOS?=linux
ARCH_LOWER?=amd64
GOLANG_ARCHIVE_PATH=$(GO_VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)/$(GO_BIN_VERSION_WITHOUT_RELEASE).$(GOOS)-$(ARCH_LOWER).tar.gz

ARCHITECTURES_TO_BUILD="amd64" "arm64"

HAS_RELEASE_BRANCHES=true

FIX_LICENSES_GO_RUNNER_TARGET=$(REPO)/images/build/go-runner/LICENSE

# include $(BASE_DIRECTORY)/Common.mk

# For 1.24 the project is built with 1.18 to match upstream but for some
# unknown reason the go-licenses project does not properly parse the go module
# with using 1.18 golang. This kind of an ugly solution
# but since we have not seen this anywhere else with 1.18 based projects the hope is
# this is super specific to this project and not something we have to do elsewhere
# if we start seeing this elsewhere we should dig in more and try to fix go-licenses
#_output/1-24/attribution/go-license.csv: GOLANG_VERSION=1.17

.PHONY: fix-licenses
fix-licenses:
#	go-licenses requires a LICENSE file in each folder with the go.mod
	cp $(REPO)/LICENSE $(FIX_LICENSES_GO_RUNNER_TARGET)
	bash $(BASE_DIRECTORY)/scripts/gather_licenses.sh release-src $(BASE_DIRECTORY)/projects/go-runner/release/_output/$(RELEASE_BRANCH)/ "." images/build/go-runner $(GO_SOURCE_VERSION)
	build/fix_licenses.sh $(OUTPUT_DIR)

########### DO NOT EDIT #############################
# To update call: make add-generated-help-block
# This is added to help document dynamic targets and support shell autocompletion
# Run make help for a formatted help block with all targets
# include Help.mk
########### END GENERATED ###########################


.PHONY: build-dependencies
build-dependencies:
	echo "Add dependencies here"
#   curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
#	curl -sL https://rpm.nodesource.com/setup_14.x | bash -
#	yum install nodejs yarn bzip2 -y

.PHONY: clone
clone: clean
	git clone $(CLONE_URL) $(REPO)
	cd $(REPO) && git checkout $(GIT_TAG)

.PHONY: buildkit-check
buildkit-check:
	$(BASE_DIRECTORY)/scripts/buildkit_check.sh

.PHONY: binaries
binaries:
#	cd images/build/go-runner
#	make -C $(REPO) build
#	export GO_BINARY_PATH=${GO_BIN}
	echo "Untar go archive for $(GOLANG_ARCHIVE_PATH)"
	tar -C $(GO_VERSION_DIRECTORY) -xvf $(GOLANG_ARCHIVE_PATH) --exclude='go/test'
#	export GOLANG_ARCHIVE_PATH=$(GO_VERSION_DIRECTORY)/archives/$(GOOS)/$(ARCH_LOWER)/$(GIT_TAG).$(GOOS)-$(ARCH_LOWER).tar.gz


	echo "Architecture is: $(ARCHITECTURES_TO_BUILD)"
	@for ARCHITECTURE in $(ARCHITECTURES_TO_BUILD); do \
		echo "Building go-runner for $${ARCHITECTURE}"; \
		$(BASE_DIRECTORY)/scripts/simple_create_binaries.sh $(BASE_DIRECTORY)/projects/go-runner \
        	$(BASE_DIRECTORY)/projects/go-runner/release/_output/$(RELEASE_BRANCH)/bin/$(GOOS)-$${ARCHITECTURE}/go-runner \
        	release-src $(GO_SOURCE_VERSION) $(GO_VERSION_DIRECTORY)/go "$(GOOS)/$${ARCHITECTURE}" "." "build" "" \
        	"-s -w -buildid= -extldflags -static " 0 "" "images/build/go-runner" "go-runner"; \
	done

	
#	cd $(BASE_DIRECTORY)/projects/go-runner/release-src
#	$(GO_BIN)/go mod vendor
#	$(GO_BIN)/go build -trimpath -a -ldflags -s -o $(BASE_DIRECTORY)/projects/go-runner/release/_output/$(RELEASE_BRANCH)/bin/release-src/linux-arm64/ .

#PROJECT_ROOT="$1"
#TARGET_FILE="$2"
#REPO="$3"
#GOLANG_VERSION="$4"
#BINARY_PLATFORMS="$5"
#SOURCE_PATTERN="$6"
#GOBUILD_COMMAND="$7" 
#EXTRA_GOBUILD_FLAGS="$8"
#GO_LDFLAGS="$9"
#CGO_ENABLED="${10}"
#CGO_LDFLAGS="${11}"
#REPO_SUBPATH="${12:-}"
#ALL_TARGET_FILES="${13:-}"

.PHONY: move-binaries
move-binaries:
	mkdir -p $(REPO)/.build/$(IMAGE_OS)-$(IMAGE_ARCH)
	mv $(REPO)/prometheus $(REPO)/.build/$(IMAGE_OS)-$(IMAGE_ARCH)/
	mv $(REPO)/promtool $(REPO)/.build/$(IMAGE_OS)-$(IMAGE_ARCH)/

.PHONY: npm_licenses
npm_licenses:
	make -C $(REPO) npm_licenses

.PHONY: local-images
local-images: npm_licenses buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--local dockerfile=./$(REPO) \
		--local context=./$(REPO) \
		--output type=oci,oci-mediatypes=true,name=$(IMAGE),dest=/tmp/prometheus.tar

.PHONY: images
images: clone binaries move-binaries npm_licenses buildkit-check
	buildctl \
		build \
		--frontend dockerfile.v0 \
		--opt platform=linux/amd64 \
		--local dockerfile=./$(REPO) \
		--local context=./$(REPO) \
		--output type=image,oci-mediatypes=true,name=$(IMAGE),push=false

.PHONY: build
build: build-dependencies clone binaries fix-licenses
#  move-binaries local-images

.PHONY: release
release: build-dependencies clone binaries move-binaries images

.PHONY: clean
clean:
	rm -rf $(REPO)


