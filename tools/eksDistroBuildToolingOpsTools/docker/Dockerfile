FROM public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base:latest

ARG BINARY_OUTPUT_PATH

ADD $BINARY_OUTPUT_PATH /usr/bin

RUN chmod +x /usr/bin/$BINARY_OUTPUT_PATH

ENTRYPOINT ["eksDistroOpsProwPlugin"]