## EKS Go Debian Base Image
This Debian base image is intended for limited use as a base for upstream Kubernetes toolchain artifacts like `kube-cross`

### Public ECR
EKS Go Debian Base Images are available through the EKS Distribution Public ECR: https://gallery.ecr.aws/eks-distro-build-tooling/golang-debian

### Image Tags
EKS Go Debian Base Images are tagged with the following format:

`$GOLANG_GIT_TAG-$EKS_GO_RELEASE-$EKS_GO_DEBIAN_DOCKERFILE_RELEASE`

For example, the Golang 1.20 Debian base image would have a tag like the following: `1.20.1-5-6`.

Where 
- `$GOLANG_GIT_TAG` is the git tag of the tracked Golang version (e.g. [for Go 1.20](../../1.20/GIT_TAG))
- `$EKS_GO_RELEASE` is the corresponding EKS Go release of the given Go version, as noted in the `RELEASE` file for the given version (e.g. [for Go 1.20](../../1.20/RELEASE)).
- `$EKS_GO_DEBIAN_DOCKERFILE_RELEASE` is the corresponding version of the dockerfile used to build the image, from the [`RELEASE` file for the Debian base image](./RELEASE)


## Releases
### 1
Initial release of EKS Go Debian AMD64 images

### 2
Move EKS Go archive path from `/usr/local` to `/usr/local/go`, in line with upstream Golang debian image

### 3
Take fixes for Go 1.16 CVE-2022-41716 patch; see https://github.com/aws/eks-distro-build-tooling/pull/728

### 4
Release for images of Go 1.19.5 and 1.18.10

### 5
Release for images of 1.20

### 6
Release for images of Go 1.19.6 and 1.20.1