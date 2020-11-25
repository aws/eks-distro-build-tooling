# EKS Distro release tooling

## Usage

### Generating a release

In the [eks-distro](https://github.com/aws/eks-distro) repo, run
```bash
CHANNEL=1-18
RELEASE_NUMBER=1
IMAGE_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
make release RELEASE_BRANCH=$CHANNEL RELEASE=$RELEASE_NUMBER IMAGE_REPO=$IMAGE_REPO
```
to build tarballs and upload container images to ECR

To create
```bash
BUILDSTEPS_REPO=/path/to/aws/eks-distro
GIT_REVISION=$(git -C $BUILDSTEPS_REPO describe --always --tags  --abbrev=64)
./bin/eks-distro-release release \
    --git-commit $GIT_REVISION \
    --image-repository $IMAGE_REPO \
    --release-branch $CHANNEL \
    --release-number $RELEASE_NUMBER \
    --source $BUILDSTEPS_REPO > kubernetes-$CHANNEL-$RELEASE_NUMBER.yaml
```


## Development

This project uses [Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
for CRD API generation.
