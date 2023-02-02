FROM public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base-builder:latest

ARG BINARY_OUTPUT_PATH

ADD $BINARY_OUTPUT_PATH /usr/bin

RUN chmod +x /usr/bin/eksDistroOpsProwPlugin

ENTRYPOINT ["eksDistroOpsProwPlugin"]
