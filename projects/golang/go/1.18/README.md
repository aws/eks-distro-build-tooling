# EKS Golang 1.18
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=*golang-1.18*-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant security fixes for go `v1.18.7`.

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go `v1.18.7` SRPM available on Amazon Linux 2, and modified to include the relevant patches and build the `v1.18.7` source.
