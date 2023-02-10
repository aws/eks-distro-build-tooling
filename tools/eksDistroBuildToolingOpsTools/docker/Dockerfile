FROM public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base-git:latest-al2

ARG BINARY_OUTPUT_PATH

ARG BINARY_NAME

ADD $BINARY_OUTPUT_PATH /usr/bin

ENTRYPOINT ["eksDistroOpsProwPlugin"]
