FROM public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base:latest

ARG BINARY_OUTPUT_PATH BINARY_NAME

ADD $BINARY_OUTPUT_PATH /usr/bin

RUN chmod +x /usr/bin/$BINARY_NAME

ENTRYPOINT [$BINARY_NAME]
