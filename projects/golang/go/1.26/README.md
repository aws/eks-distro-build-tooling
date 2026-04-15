# EKS Golang 1.26

Current Release: `0`

Tracking Tag: `go1.26.2`

Artifacts: https://distro.eks.amazonaws.com/golang-go1.26/releases/0/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.26-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.26-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `1.26`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go 1.26 SRPM available on Fedora, and modified to include the relevant patches and build the `go1.26.2` source.

