# EKS Golang 1.19

Current Release: `10`

Tracking Tag: `go1.19.12`

Artifacts: https://distro.eks.amazonaws.com/golang-go1.19/releases/3/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.19-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.19-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `1.19`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go 1.19 SRPM available on Fedora, and modified to include the relevant patches and build the `go1.19.4` source.

