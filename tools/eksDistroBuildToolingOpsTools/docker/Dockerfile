FROM public.ecr.aws/eks-distro-build-tooling/eks-distro-base:latest

ARG BINARY_OUTPUT_PATH

ARG BINARY_NAME
ENV OPS_TOOL_BINARY=$BINARY_NAME

ADD $BINARY_OUTPUT_PATH /usr/bin

RUN chmod +x /usr/bin/$BINARY_NAME

RUN yum install git

ENTRYPOINT ["eksDistroOpsProwPlugin"]
