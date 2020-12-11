# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG BASE_IMAGE=amazonlinux:2

FROM ${BASE_IMAGE}

ARG TARGETARCH=amd64
ARG TARGETOS=linux
ARG GOLANG_DOWNLOAD_URL=https://golang.org/dl
ARG GOLANG_VERSION
ARG GOLANG_CHECKSUM
ARG BUILDKIT_VERSION
ARG BUILDKIT_CHECKSUM

RUN yum upgrade -y \
    && yum update -y \
    && amazon-linux-extras enable docker \
    && yum install -y \
        awscli \
        amazon-ecr-credential-helper \
        curl \
        gcc \
        git \
        jq \
        less \
        make \
        man \
        procps-ng \
        python3-pip \
        rsync \
        tar \
        vim \
        wget \
        which

RUN wget \
      --progress dot:giga \
      --max-redirect=1 \
      "${GOLANG_DOWNLOAD_URL}/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && echo "${GOLANG_CHECKSUM} go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" | sha256sum -c \
    && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz \
    && rm go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz \
    && mv /usr/local/go/bin/* /usr/bin/ \
    && wget \
        --progress dot:giga \
        "https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/buildkit-${BUILDKIT_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && echo "${BUILDKIT_CHECKSUM} buildkit-${BUILDKIT_VERSION}.linux-${TARGETARCH}.tar.gz" | sha256sum -c \
    && tar -C /usr -xzf buildkit-${BUILDKIT_VERSION}.linux-${TARGETARCH}.tar.gz \
    && rm -rf buildkit-${BUILDKIT_VERSION}.linux-${TARGETARCH}.tar.gz \
    && mkdir -p /go/src /go/bin /go/pkg /go/src/github.com/aws/eks-distro

ENV GOPATH /go
WORKDIR /go/src/github.com/aws/eks-distro
