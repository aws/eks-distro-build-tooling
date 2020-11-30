#!/usr/bin/env bash
#Script to check for updates and push new EKS Distro base image to ECR and create PRs on Github

set -e
set -o pipefail
set -x

yum --security check-update
if [ $? -eq 100 ]; then
    bash ./eks-distro-base/install.sh
    export TZ=America/Los_Angeles
    DATE_EPOCH=$(date "+%F-%s")
    make release -C eks-distro-base DEVELOPMENT=false IMAGE_TAG=${DATE_EPOCH}
    bash ./eks-distro-base/create_pr.sh eks-distro-build-tooling '.*' ${DATE_EPOCH} eks-distro-base/TAG_FILE
    bash ./eks-distro-base/create_pr.sh eks-distro 'BASE_TAG?=.*' 'BASE_TAG?='"${DATE_EPOCH}" Makefile
    bash ./eks-distro-base/create_pr.sh eks-distro-prow-jobs '\(eks-distro/base\):.*' '\1:'"${DATE_EPOCH}" jobs/aws/eks-distro-build-tooling/eks-distro-base-periodics.yaml
fi
