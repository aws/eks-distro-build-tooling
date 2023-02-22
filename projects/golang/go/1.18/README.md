# EKS Golang 1.18

Current Release: `2`

Tracking Tag: `go1.18.10`

Artifacts: https://distro.eks.amazonaws.com/golang-go1.18/releases/2/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.18-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.18-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `1.18`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go 1.18 SRPM available on Fedora, and modified to include the relevant patches and build the `go1.18.9` source.

