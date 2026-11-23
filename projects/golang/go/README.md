# Golang Debian Images

This project builds the `golang-debian` images published to https://gallery.ecr.aws/eks-distro-build-tooling/golang-debian.
Each image contains the upstream Go release binaries from https://go.dev/dl on a Debian base.

## Versions

The Go minor versions and their patch versions are listed in [`eks-distro-base/golang_versions.yaml`](../../../eks-distro-base/golang_versions.yaml).
Each minor version has a `RELEASE` file in this directory that holds its image build release.

## Building

The `golang-debian-images-presubmit` and `golang-debian-images-postsubmit` Prow jobs run `make prod-release-images-upstream-bins-all`.
The target builds one image per Go minor version.
When `PUSH_IMAGES=true`, it skips any image whose build inputs have not changed since it was last pushed.
The presubmit sets `PUSH_IMAGES=false` and always builds every version.

To build one version locally without pushing, run `make local-images-upstream-bins GO_SOURCE_VERSION=1.26 IMAGE_REPO=localhost:5000`.

See the [Debian base image README](./docker/debianBase/README.md) for the image tag format.
