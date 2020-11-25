ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY golang-checksum /golang-checksum
COPY buildkit-checksum /buildkit-checksum
COPY install.sh /opt/install.sh
RUN bash /opt/install.sh

ENV GOPATH /go
WORKDIR /go/src/github.com/aws/eks-distro
