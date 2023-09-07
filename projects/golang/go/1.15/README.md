# EKS Golang 1.15

Current Release: `7`

Tracking Tag: `1.15.1`

Artifacts: https://distro.eks.amazonaws.com/golang-go1.15/releases/7/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.15-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.15-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `1.15`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go 1.15 SRPM available on Fedora, and modified to include the relevant patches and build the `v1.15.1` source.
