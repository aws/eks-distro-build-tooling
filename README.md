## EKS Distro Build Tooling Repository

[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=*-base-postsubmit)](https://prow.eks.amazonaws.com/?type=postsubmit)

This repository contains tooling used to build the [EKS
Distro](https://distro.eks.amazonaws.com), and all the projects contained in
https://github.com/aws/eks-distro.

### builder-base

bulider-base contains a Dockerfile and install scripting for building a
container image used to run [prow
jobs](https://github.com/aws/eks-distro-prow-jobs) in our [prow
cluster](https://prow.eks.amazonaws.com).

### eks-distro-base

eks-distro-base contains a Dockerfile used to build an up-to-date Amazon Linux 2
base image. This base will be updated whenever there are any security updates to
RPMs contained in the base image.

### helm-charts

The helm-charts directory contains [Helm](https://helm.sh) charts used to
operate Prow and supporting tooling on the Prow EKS clusters. These charts are
not considered stable for external use.

### release

The release directory contains release tooling and build code for generating EKS
Distro release CRDs.

## Security

If you discover a potential security issue in this project, or think you may
have discovered a security issue, we ask that you notify AWS Security via our
[vulnerability reporting
page](http://aws.amazon.com/security/vulnerability-reporting/). Please do
**not** create a public GitHub issue.

## License

This project is licensed under the Apache-2.0 License.
