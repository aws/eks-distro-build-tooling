FROM public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base-git:latest-al2

ARG BINARY_OUTPUT_PATH

ARG BINARY_NAME

ADD $BINARY_OUTPUT_PATH /usr/bin

ENTRYPOINT ["eksDistroOpsProwPlugin", "--github-token-path=/etc/github/token", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--dry-run=false" ]
