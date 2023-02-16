# builder-base container image

This image is used as the base for building other jobs. It is a base image for most prow jobs.

New builds of this image will automatically raise a PR to update the image tags in the prowjobs in the aws/eks-distro-prow-jobs repo.

You can pull these images from the [ECR Public Gallery](https://gallery.ecr.aws/eks-distro-build-tooling/builder-base).
