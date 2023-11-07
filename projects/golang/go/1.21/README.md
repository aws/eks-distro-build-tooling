# EKS Golang 1.21

Current Release: `5`

Tracking Tag: `go1.21.4`

### Artifacts:  
|Arch|Artifact|sha|
|:---:|:---:|:---:|
|noarch|[golang-src-1.21.4-5.amzn2.eks.noarch.rpm](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/x86_64/RPMS/noarch/golang-src-1.21.4-5.amzn2.eks.noarch.rpm)|[golang-src-1.21.4-5.amzn2.eks.noarch.rpm.sha256](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/x86_64/RPMS/noarch/golang-src-1.21.4-5.amzn2.eks.noarch.rpm.sha256)|
|x86_64|[golang-1.21.4-5.amzn2.eks.x86_64.rpm](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/x86_64/RPMS/x86_64/golang-1.21.4-5.amzn2.eks.x86_64.rpm)|[golang-1.21.4-5.amzn2.eks.x86_64.rpm.sha256](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/x86_64/RPMS/x86_64/golang-1.21.4-5.amzn2.eks.x86_64.rpm.sha256)|
|aarch64|[golang-1.21.4-5.amzn2.eks.aarch64.rpm](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/aarch64/RPMS/aarch64/golang-1.21.4-5.amzn2.eks.aarch64.rpm)|[golang-1.21.4-5.amzn2.eks.aarch64.rpm.sha256](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/aarch64/RPMS/aarch64/golang-1.21.4-5.amzn2.eks.aarch64.rpm.sha256)|
|arm64|[go1.21.4.linux-arm64.tar.gz](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/archives/linux/arm64/go1.21.4.linux-arm64.tar.gz)|[go1.21.4.linux-arm64.tar.gz.sha256](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/archives/linux/arm64/go1.21.4.linux-arm64.tar.gz.sha256)|
|amd64|[go1.21.4.linux-amd64.tar.gz](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/archives/linux/amd64/go1.21.4.linux-amd64.tar.gz)|[go1.21.4.linux-amd64.tar.gz.sha256](https://distro.eks.amazonaws.com/golang-go1.21.4/releases/5/archives/linux/amd64/go1.21.4.linux-amd64.tar.gz.sha256)|


### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1-21-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1-21-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `1.21`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go 1.21 SRPM available on Fedora, and modified to include the relevant patches and build the `go1.21` source.
