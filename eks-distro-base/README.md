# eks-distro/base container image

This image is used as the base image for building images of our deliverable projects such as coredns, metrics-server, etc.

New builds of this image will automatically raise a PR to update the image tags in the EKS_DISTRO_BASE_TAG_FILE in this repo and in the aws/eks-distro repo.

You can pull these images from the [ECR Public Gallery](https://gallery.ecr.aws/eks-distro-build-tooling/eks-distro-base).
