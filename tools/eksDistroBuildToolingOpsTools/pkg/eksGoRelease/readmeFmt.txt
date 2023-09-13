# EKS Golang %s

Current Release: `%d`

Tracking Tag: `%s`

Artifacts: https://distro.eks.amazonaws.com/golang-go%s/releases/%d/RPMS

### ARM64 Builds
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%s-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds\n[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%s-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `%s`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go %s SRPM available on Fedora, and modified to include the relevant patches and build the `%s` source."
