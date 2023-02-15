## EKS Go Debian Base Image
This Debian base image is inteneded for limited use as a base for upstream Kubernetes toolchain artifacts like `kube-cross`

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

### 5
Release for images of Go 1.19.6 and 1.20.1