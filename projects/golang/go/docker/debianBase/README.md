## Golang Debian Base Image
This Debian base image is intended for limited use as a base for upstream Kubernetes toolchain artifacts like `kube-cross`.
It contains the upstream Go release binaries from https://go.dev/dl.

### Public ECR
Golang Debian base images are available through the EKS Distro Public ECR: https://gallery.ecr.aws/eks-distro-build-tooling/golang-debian

### Image Tags
Golang Debian base images are tagged with the following format:

`go$GOLANG_VERSION-$BUILD_RELEASE-$DEBIAN_DOCKERFILE_RELEASE`

For example, the Go 1.26.11 image built from build release 1 and Dockerfile release 25 is tagged `go1.26.11-1-25`.

Where
- `$GOLANG_VERSION` is the Go patch version for that minor version in [`eks-distro-base/golang_versions.yaml`](../../../../../eks-distro-base/golang_versions.yaml).
- `$BUILD_RELEASE` is the build release for that minor version, from its `RELEASE` file, for example [the Go 1.26 `RELEASE` file](../../1.26/RELEASE).
- `$DEBIAN_DOCKERFILE_RELEASE` is the release of the Dockerfile used to build the image, from the [`RELEASE` file for the Debian base image](./RELEASE).
