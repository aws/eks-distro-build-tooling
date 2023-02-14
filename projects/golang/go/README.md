# EKS Go
EKS supports a [larger set](#supported-versions) of Golang version than upstream Golang. 

These versions are used to build Kubernetes and other Kubernetes ecosystem components used by EKS. 
Relevant upstream security fixes are backported to these Go versions. 
These patched versions are then built into RPMs and tested by building the relevant version of EKS Distro (e.g. Go 1.16 and Kubernetes 1.21) 
and executing the Kubernetes conformance tests.

EKS Go RPMs are publicly available; see [Access EKS Go Artifacts](#access-eks-go-artifacts). 


## Supported Versions
EKS currently supports the following Golang versions:
- [`v1.15`](./1.15/GIT_TAG)
- [`v1.16`](./1.16/GIT_TAG)
- [`v1.17`](./1.17/GIT_TAG)
- [`v1.18`](./1.18/GIT_TAG)
- [`v1.19`](./1.19/GIT_TAG)
- [`v1.20`](./1.20/GIT_TAG)

## Upstream Patches
EKS Golang Versions are distributed as RPMs built from upstream Golang source for the given version.  
Relevant security and utility patches, and their tests, are backported and applied as patches during the RPM build.
The patches applied to a given version of Golang are stored in the [EKS Distro Build Tooling Github repository](https://github.com/aws/eks-distro-build-tooling/tree/main/projects/golang/go), alongside the build system for EKS Golang. For example, you can see the patches associated with EKS Go v1.16 [here](https://github.com/aws/eks-distro-build-tooling/tree/main/projects/golang/go/1.16/patches).

## EKS Go RPMs
For each supported version of Go, there are 6 RPMS: 3 architecture-specific and 4 architecture-independent.

Architecture Specific RPMs:
- `golang`
- `golang-bin`

Architecture Independent RPMs:
- `golang-docs`
- `golang-misc`
- `golang-tests`
- `golang-src`

## EKS Go RPM Validation
To ensure the Golang RPM files aren’t corrupted during the transit when the Go artifacts are uploaded and downloaded, sha256sum files are generated during the build against each EKS Go RPMs. Each sha256sum file contains a sha256sum value against corresponding Golang RPM that was generated during the build.

Architecture Specific RPM sha256sums:
- `golang-*version*.rpm.sha256`
- `golang-bin-*version*.rpm.sha256`

Architecture Independent RPM sha256sums:
- `golang-docs-*version*.rpm.sha256`
- `golang-misc-*version*.rpm.sha256`
- `golang-tests-*version*.rpm.sha256`
- `golang-src-*version*.rpm.sha256`

The sha256sum files for architecture specific RPMs are available at URLs following the schema:

`golang-go$MINOR_VERSION.$PATCH_VERSION/releases/$RELEASE/$ARCHITECTURE/RPMS/$ARCHITECTURE/golang-$MINOR_VERSION.$PATCH_VERSION-$RELEASE.amzn2.eks.$ARCHITECTURE.rpm.sha256`

The sha256sum files for architecture independent RPMs are available at URLs following the schema:

`golang-go$MINOR_VERSION.$PATCH_VERSION/releases/$RELEASE/$ARCHITECTURE/RPMS/$ARCHITECTURE/golang-$MINOR_VERSION.$PATCH_VERSION-$RELEASE.amzn2.eks.noarch.rpm.sha256`

During Golang installation these sha256sum files containing checksum values are validated against the downloaded Golang RPMs to ensure Golang RPM integrity.

## EKS Go architectures
EKS Go currently supports the following architectures:
- `x86_64`
- `aarch64`

## Access EKS Go Artifacts

EKS Go RPMs are available through the EKS Distro CDN at https://distro.eks.amazonaws.com.

Artifacts are available at URLs following the schema:

`golang-go$MINOR_VERSION.$PATCH_VERSION/releases/$RELEASE/$ARCHITECTURE/RPMS/$ARCHITECTURE/golang-$MINOR_VERSION.$PATCH_VERSION-$RELEASE.amzn2.eks.$ARCHITECTURE.rpm`

Where `$ARCHITECTURE` is one of:
- `x86_64` for AMD64
- `aarch64` for ARM64
- `noarch` for architecture-independent components

Where `$RELEASE` is the release number of the given EKS Go version. 
You can find the latest release of a given EKS Go version in the `RELEASE` tag file for the given Go version. 
For example, [the latest EKS release of Go `1.19` can be found here](./1.19/RELEASE). 

For example, the first release of the Golang `1.16.15` RPM is available at the following URL:

https://distro.eks.amazonaws.com/golang-go1.16.15/releases/1/RPMS/x86_64/golang-1.16.15-1.amzn2.eks.x86_64.rpm

### EKS Go Debian Base Image
EKS Go maintains a Debian-based image containing EKS Go for use with the upstream Kubernetes toolchahin.
You can find the Dockerfile and more information [here](https://github.com/aws/eks-distro-build-tooling/tree/main/projects/golang/go/docker/debianBase).


## Getting Started
### Installing EKS Golang on x86_64 Amazon Linux

This example demonstrates how to install the entire EKS Golang 1.16.15 system on a `x86_64` architecture Amazon Linux machine using `yum localinstall`.

Each artifact is avilable through the EKS Distro CDN, available at https://distro.eks.amazonaws.com. 
In this example, we download the objects using `curl`, storing them in a temporary directory, 
and then install them all at one, taking dependency between the RPMs into account using `yum localinstall`. 

To install a different EKS supported Go version, modify the `version`, `arch`, or `release` variable to reflect the EKS Go variant you wish to install.

```bash
# EKS Golang version
version='1.16.15'

# EK Go Release
release='1'

# either x86_64 or aarch64
arch='x86_64'

mkdir /tmp/go$version

# download architecture-specific RPMs
for artifact in golang golang-bin golang-race; do
    curl https://distro.eks.amazonaws.com/golang-go$version/releases/$release/$arch/RPMS/$arch/$artifact-$version-$release.amzn2.eks.$arch.rpm -o /tmp/go$version/$artifact-$version-$release.amzn2.eks.$arch.rpm
done

# download architecture independent RPMs
for artifact in golang-docs golang-misc golang-tests golang-src; do
    curl https://distro.eks.amazonaws.com/golang-go$version/releases/$release/$arch/RPMS/noarch/$artifact-$version-$release.amzn2.eks.noarch.rpm -o /tmp/go$version/$artifact-$version-$release.amzn2.eks.noarch.rpm
done

yum -y localinstall /tmp/go$version/golang*

# show that we've installed go and what version it is
which go

go version
```
