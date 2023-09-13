# EKS Golang %s

Current Release: `%d`

Tracking Tag: `go%s`

### Artifacts:  
|Arch|Artifact|sha|
|:---:|:---:|:---:|
%s

### ARM64 Builds
[![Build status](%s)](https://prow.eks.amazonaws.com/?repo=aws%%2Feks-distro-build-tooling&type=postsubmit)

### AMD64 Builds
[![Build status](%s)](https://prow.eks.amazonaws.com/?repo=aws%%2Feks-distro-build-tooling&type=postsubmit)

### Patches
The patches in `./patches` include relevant utility fixes for go `%s`.

### Spec
<<<<<<< HEAD
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go %s SRPM available on Fedora, and modified to include the relevant patches and build the `go%s` source."
