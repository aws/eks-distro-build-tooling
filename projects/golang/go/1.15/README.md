## Golang 1.15.15 Build for EKS
### Patches
The patches in `./patches` include relevant security fixes for go `v1.15.15` which have been released since `v1.15.15` left support. 

### Spec
The RPM spec file in `./rpmbuild/SPECS` is sourced from the go `v1.15.14` SRPM available on Amazon Linux 2, and modified to include the relevant patches and build the `v1.15.15` source.

