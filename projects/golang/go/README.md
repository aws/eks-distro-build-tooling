# EKS Supported Go Versions
EKS supports a larger set of Golang version than upstream Golang. These versions are used to build Kubernetes and other Kubernetes ecosystem components used by EKS. Relevant upstream security fixes are backported to these Go versions. These patched versions are then built into RPMs and tested by building the relevant version of EKS Distro (e.g. Go 1.16 and Kubernetes 1.21) and executing the Kubernetes conformance tests.

## Upstream Patches
EKS Golang Versions are distributed as RPMs built from upstream Golang source for the given version with relevant security and utility patches, and their tests, backported.
The patches applied to a given version of Golang are stored in the [EKS Distro Build Tooling Github repository](https://github.com/aws/eks-distro-build-tooling/tree/main/projects/golang/go), alongside the build system for EKS Golang. For example, you can see the patches associated with EKS Go v1.16 [here](https://github.com/aws/eks-distro-build-tooling/tree/main/projects/golang/go/1.16/patches). 

EKS currently supports the following Golang versions:
- Go v1.15.15
- Go v1.16.15

EKS Go plans to support all relevant versions of Go (e.g. those used by a supported Kubernetes version or other Kubernetes ecosystem component) in the near future.

## EKS Go architectures
EKS Go currently supports the following architectures:
- `x86_64`

EKS Go plans to support ARM in the near future.

## EKS Go RPMs
For each supported version of Go, there are 6 RPMS: 3 architecture-specific and 4 architecture-independent.

Architecture Specific RPMs:
- golang
- golang-bin
- golang-race

Architecture Independent RPMs:
- golang-docs
- golang-misc
- golang-tests
- golang-src

## Installing EKS Golang on x86_64 Amazon Linux

This example demonstrates how to install the entire EKS Golang 1.16.15 system on a `x86_64` architecture Amazon Linux machine using `yum localinstall`.

Each artifact is stored in a public-read S3 bucket, `eks-d-postsubmit-artifacts`. In this example, we download the objects using `curl`, storing them in a temporary directory, and then install them all at one, taking dependency between the RPMs into account using `yum localinstall`. 

To install a different EKS supported Go version, modify the `version` variable to relfect the version you wish to install.

```bash
# EKS Golang version
version='1.16.15'

# A public-read S3 bucket which holds the RPMs built by EKS
artifacts_bucket='eks-d-postsubmit-artifacts'

# Currently, the only supported archtiecture is AMD64
arch='x86_64'

mkdir /tmp/go$version

for artifact in golang golang-bin golang-race; do
    curl https://$artifacts_bucket.s3.amazonaws.com/golang/go/go$version/RPMS/$arch/$artifact-$version-1.amzn2.0.1.$arch.rpm -o /tmp/go$version/$artifact-$version-1.amzn2.0.1.$arch.rpm
done

for artifact in golang-docs golang-misc golang-tests golang-src; do
    curl https://$artifacts_bucket.s3.amazonaws.com/golang/go/go$version/RPMS/noarch/$artifact-$version-1.amzn2.0.1.noarch.rpm -o /tmp/go$version/$artifact-$version-1.amzn2.0.1.noarch.rpm
done

yum -y localinstall /tmp/go$version/golang*

# show that we've installed go and what version it is
which go

go version
```

