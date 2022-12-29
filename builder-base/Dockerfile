# syntax=docker/dockerfile:1.4
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
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

# Intentionally redo-ing yum installs in all layers to keep all
# layers independent, reducing rebuilds and better using 
# image and buildkitd cache

ARG BUILDER_IMAGE
ARG BASE_IMAGE
ARG FINAL_STAGE_BASE


FROM ${BUILDER_IMAGE} as aws-cli
ARG TARGETARCH
WORKDIR /workdir
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_aws_cli.sh /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_aws_cli.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as buildkit
ARG TARGETARCH
WORKDIR /workdir
ARG BUILDKIT_VERSION
ENV BUILDKIT_VERSION=$BUILDKIT_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_buildkit.sh ./checksums/buildkit-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_buildkit.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as ecr-cred-helper
ARG TARGETARCH
WORKDIR /workdir
ARG AMAZON_ECR_CRED_HELPER_VERSION
ENV AMAZON_ECR_CRED_HELPER_VERSION=$AMAZON_ECR_CRED_HELPER_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_ecr_cred_helper.sh ./checksums/amazon-ecr-cred-helper-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_ecr_cred_helper.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as gh_cli
ARG TARGETARCH
WORKDIR /workdir
ARG GITHUB_CLI_VERSION
ENV GITHUB_CLI_VERSION=$GITHUB_CLI_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_gh_cli.sh ./checksums/github-cli-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_gh_cli.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as docker_buildx
ARG TARGETARCH
WORKDIR /workdir
ARG DOCKER_BUILDX_VERSION
ENV DOCKER_BUILDX_VERSION=$DOCKER_BUILDX_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_docker_buildx.sh ./checksums/docker-buildx-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_docker_buildx.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as yq
ARG TARGETARCH
WORKDIR /workdir
ARG YQ_VERSION
ENV YQ_VERSION=$YQ_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_yq.sh ./checksums/yq-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_yq.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as packer
ARG TARGETARCH
WORKDIR /workdir
ARG PACKER_VERSION
ENV PACKER_VERSION=$PACKER_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_packer.sh ./checksums/packer-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_packer.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as helm
ARG TARGETARCH
WORKDIR /workdir
ARG HELM_VERSION
ENV HELM_VERSION=$HELM_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_helm.sh ./checksums/helm-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_helm.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as nodejs
ARG TARGETARCH
WORKDIR /workdir
ARG NODEJS_VERSION
ENV NODEJS_VERSION=$NODEJS_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_nodejs.sh \
    generate-attribution/package*.json  \
    generate-attribution/generate-attribution  \
    generate-attribution/generate-attribution-file.js \ 
    generate-attribution/LICENSE-2.0.txt \
    ./checksums/nodejs-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_nodejs.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as hugo
ARG TARGETARCH
WORKDIR /workdir
ARG HUGO_VERSION
ENV HUGO_VERSION=$HUGO_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_hugo.sh ./checksums/hugo-amd64-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_hugo.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as govc
ARG TARGETARCH
WORKDIR /workdir
ARG GOVC_VERSION
ENV GOVC_VERSION=$GOVC_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_govc.sh ./checksums/govc-${TARGETARCH}-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_govc.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as goss
ARG TARGETARCH
WORKDIR /workdir
ARG GOSS_VERSION
ENV GOSS_VERSION=$GOSS_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_goss.sh ./checksums/goss-amd64-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_goss.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE}  as tuftool
ARG TARGETARCH
WORKDIR /workdir
ENV CARGO_HOME /root/.cargo
ENV RUSTUP_HOME /root/.rustup
ENV PATH="/root/.cargo/bin:$PATH"
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/install_gcc_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_tuftool.sh /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_gcc_yum_packages.sh && \
    /install_tuftool.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE}  as bash
ARG TARGETARCH
WORKDIR /workdir
ARG OVERRIDE_BASH_VERSION
ENV OVERRIDE_BASH_VERSION=$OVERRIDE_BASH_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/install_gcc_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/common_vars.sh ./scripts/install_bash.sh ./checksums/bash-checksum /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_gcc_yum_packages.sh && \
    /install_bash.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as ansible
ARG TARGETARCH
WORKDIR /workdir
ARG ANSIBLE_VERSION
ENV ANSIBLE_VERSION=$ANSIBLE_VERSION
ARG PYWINRM_VERSION
ENV PYWINRM_VERSION=$PYWINRM_VERSION
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_ansible.sh /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_ansible.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as golang-1.15
ARG TARGETARCH
ARG GOLANG_VERSION_115
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_golang.sh /
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_golang.sh $GOLANG_VERSION_115 && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as golang-1.16
ARG TARGETARCH
ARG GOLANG_VERSION_116
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_golang.sh /
ADD $GOLANG_RPM_SOURCE_DIR/golang-1.16*.rpm /tmp/
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_golang.sh $GOLANG_VERSION_116 && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as golang-1.17
ARG TARGETARCH
ARG GOLANG_VERSION_117
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_golang.sh /
ADD $GOLANG_RPM_SOURCE_DIR/golang-1.17*.rpm /tmp/
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_golang.sh $GOLANG_VERSION_117 && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as golang-1.18
ARG TARGETARCH
ARG GOLANG_VERSION_118
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_golang.sh /
ADD $GOLANG_RPM_SOURCE_DIR/golang-1.18*.rpm /tmp/
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_golang.sh $GOLANG_VERSION_118 && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as golang-1.19
ARG TARGETARCH
ARG GOLANG_VERSION_119
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_golang.sh /
ADD $GOLANG_RPM_SOURCE_DIR/golang-1.19*.rpm /tmp/
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_base_yum_packages.sh && \
    /install_golang.sh $GOLANG_VERSION_119 && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as skopeo
ARG TARGETARCH
ARG GOPROXY
ARG SKOPEO_VERSION
ENV SKOPEO_VERSION=$SKOPEO_VERSION
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY --link --from=golang-1.16 /golang-1.16 /
COPY ./scripts/install_base_yum_packages.sh ./scripts/remove_yum_packages.sh ./scripts/install_gcc_yum_packages.sh ./scripts/common_vars.sh \
    ./scripts/install_skopeo.sh /
RUN --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    /install_gcc_yum_packages.sh && \
    /install_skopeo.sh && \
    /remove_yum_packages.sh

FROM ${BUILDER_IMAGE} as linuxkit
ARG TARGETARCH
ARG GOPROXY
ARG LINUXKIT_VERSION
ENV LINUXKIT_VERSION=$LINUXKIT_VERSION
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY --link --from=golang-1.16 /golang-1.16 /
COPY ./scripts/common_vars.sh \
    ./scripts/install_linuxkit.sh /
RUN --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    --mount=type=secret,id=netrc,target=/root/.netrc \    
    /install_linuxkit.sh    

FROM ${BUILDER_IMAGE} as go-licenses-1.16
ARG TARGETARCH
ARG GOPROXY
ARG GO_LICENSES_VERSION
ENV GO_LICENSES_VERSION=$GO_LICENSES_VERSION
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY --link --from=golang-1.16 /golang-1.16 /
COPY ./scripts/common_vars.sh \
    ./scripts/install_go_licenses.sh /
RUN --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    /install_go_licenses.sh

FROM ${BUILDER_IMAGE} as go-licenses-1.17
ARG TARGETARCH
ARG GOPROXY
ARG GO_LICENSES_VERSION
ENV GO_LICENSES_VERSION=$GO_LICENSES_VERSION
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY --link --from=golang-1.17 /golang-1.17 /
COPY ./scripts/common_vars.sh \
    ./scripts/install_go_licenses.sh /
RUN --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    /install_go_licenses.sh

FROM ${BUILDER_IMAGE} as go-licenses-1.18
ARG TARGETARCH
ARG GOPROXY
ARG GO_LICENSES_VERSION
ENV GO_LICENSES_VERSION=$GO_LICENSES_VERSION
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY --link --from=golang-1.18 /golang-1.18 /
COPY ./scripts/common_vars.sh \
    ./scripts/install_go_licenses.sh /
RUN --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    /install_go_licenses.sh

FROM ${BUILDER_IMAGE} as go-licenses-1.19
ARG TARGETARCH
ARG GOPROXY
ARG GO_LICENSES_VERSION
ENV GO_LICENSES_VERSION=$GO_LICENSES_VERSION
WORKDIR /workdir
ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"
COPY --link --from=golang-1.19 /golang-1.19 /
COPY ./scripts/common_vars.sh \
    ./scripts/install_go_licenses.sh /
RUN --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    /install_go_licenses.sh


FROM ${BASE_IMAGE} as minimal-copy-stage

# Ordered by least likely to be updated
COPY --link --from=bash /bash /
COPY --link --from=aws-cli /aws-cli /
COPY --link --from=ecr-cred-helper /ecr-cred-helper /
COPY --link --from=yq /yq /
COPY --link --from=gh_cli /gh-cli /
COPY --link --from=hugo /hugo /
COPY --link --from=goss /goss /
COPY --link --from=govc /govc /
COPY --link --from=helm /helm /
COPY --link --from=tuftool /tuftool /
COPY --link --from=docker_buildx /docker_buildx /
COPY --link --from=buildkit /buildkit /
COPY --link --from=skopeo /skopeo /

FROM minimal-copy-stage as full-copy-stage

COPY --link --from=packer /packer /
COPY --link --from=ansible /ansible /
COPY --link --from=nodejs /nodejs /
COPY --link --from=golang-1.15 /golang-1.15 /
COPY --link --from=golang-1.16 /golang-1.16 /
COPY --link --from=linuxkit /linuxkit /
COPY --link --from=golang-1.17 /golang-1.17 /
COPY --link --from=go-licenses-1.17 /go-licenses-1.17 /
COPY --link --from=golang-1.19 /golang-1.19 /
COPY --link --from=go-licenses-1.19 /go-licenses-1.19 /
# add the default golang verison last so its /usr/bin/go
# takes precendent
COPY --link --from=golang-1.18 /golang-1.18 /
COPY --link --from=go-licenses-1.18 /go-licenses-1.18 /
COPY --link --from=go-licenses-1.16 /go-licenses-1.16 /

FROM ${FINAL_STAGE_BASE} as final

ARG TARGETARCH
ARG FINAL_STAGE_BASE

ENV GOPATH /go
ENV PATH="/go/bin/:$PATH"

COPY ./scripts/docker.sh ./scripts/buildkit.sh ./scripts/common_vars.sh ./scripts/validate_components.sh \
    ./scripts/install_final.sh /

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    /install_final.sh && \
    /validate_components.sh && \
    rm /common_vars.sh /validate_components.sh /install_final.sh
