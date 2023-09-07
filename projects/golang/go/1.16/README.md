# EKS Golang 1.16

Current Release: `8`

Tracking Tag: `1.16.2`

Artifacts: https://distro.eks.amazonaws.com/golang-go1.16/releases/8/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.16-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.16-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `1.16`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go 1.16 SRPM available on Fedora, and modified to include the relevant patches and build the `v1.16.2` source.
