## Golang 1.15.15 Build for EKS
### ARM64 Builds 
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.15-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds 
[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-1.15-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant security fixes for go `v1.15.15` which have been released since `v1.15.15` left support. 

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go `v1.15.14` SRPM available on Amazon Linux 2, and modified to include the relevant patches and build the `v1.15.15` source.

