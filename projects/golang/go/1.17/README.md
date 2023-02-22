# EKS Golang 1.17

Current Release: `3`

Tracking Tag: `go1.17.13`

Artifacts: https://distro.eks.amazonaws.com/golang-go1.17/releases/3/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.17-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.17-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant security fixes for go `v1.17.13` which have been released since `1.17.13` left support.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go `v1.16.14` SRPM available on Amazon Linux 2, and modified to include the relevant patches and build the `1.17.13` source.
