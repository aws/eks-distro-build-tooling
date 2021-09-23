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

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG GOPROXY

ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"

COPY *-checksum /
COPY buildkit.sh /buildkit.sh
COPY docker.sh /docker.sh
COPY install.sh /opt/install.sh

# attribution generation support
COPY generate-attribution/package*.json \
    generate-attribution/generate-attribution \
    generate-attribution/generate-attribution-file.js \
    generate-attribution/LICENSE-2.0.txt \ 
    /opt/generate-attribution/

RUN export GOPROXY=${GOPROXY} && \
    bash /opt/install.sh && \
    rm /opt/install.sh /*-checksum

WORKDIR /go/src/github.com/aws/eks-distro
