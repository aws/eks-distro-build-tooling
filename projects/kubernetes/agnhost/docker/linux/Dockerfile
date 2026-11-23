# Rebuilds upstream agnhost so the image carries no known CRITICAL/HIGH CVEs.
#
# Upstream registry.k8s.io/e2e-test-images/agnhost tags are frozen: the
# /agnhost binary keeps the Go toolchain and modules it was built with, and the
# Alpine base goes out of support. This image:
#   - builds /agnhost from the same kubernetes commit upstream used, with a
#     patched Go toolchain and the module bumps listed in GO_DEPENDENCY_BUMPS
#   - uses a supported Alpine release instead of upstream's
#   - copies every other file (coredns, porter certs, fake registry content)
#     from the upstream image unchanged, so test behavior does not change.

ARG BASE_IMAGE
ARG GOLANG_IMAGE
ARG ALPINE_IMAGE

FROM --platform=$BUILDPLATFORM $GOLANG_IMAGE AS builder
ARG TARGETARCH
ARG KUBERNETES_COMMIT
ARG AGNHOST_VERSION
ARG GOPROXY=https://proxy.golang.org,direct
ENV GOPROXY=$GOPROXY GOWORK=off GOFLAGS=-mod=mod CGO_ENABLED=0

ADD https://github.com/kubernetes/kubernetes/archive/${KUBERNETES_COMMIT}.tar.gz /kubernetes.tar.gz
RUN mkdir /kubernetes && tar -xzf /kubernetes.tar.gz --strip-components=1 -C /kubernetes && rm /kubernetes.tar.gz
WORKDIR /kubernetes
COPY GO_DEPENDENCY_BUMPS /GO_DEPENDENCY_BUMPS
RUN go get $(cat /GO_DEPENDENCY_BUMPS)
RUN cd test/images/agnhost && \
    GOOS=linux GOARCH=$TARGETARCH go build -buildvcs=false -a -installsuffix cgo \
      -ldflags "-w -X main.Version=${AGNHOST_VERSION}" -o /agnhost .

FROM $BASE_IMAGE AS upstream

FROM $ALPINE_IMAGE
ARG KUBERNETES_COMMIT
ARG AGNHOST_VERSION

# Same package set as upstream test/images/agnhost/Dockerfile.
RUN apk --no-cache upgrade && \
    apk --no-cache add bind-tools curl netcat-openbsd iproute2 iperf bash util-linux-misc socat && \
    ln -s /usr/bin/iperf /usr/local/bin/iperf

COPY --from=upstream /coredns /coredns
EXPOSE 80 8080 8081 9376 5000
RUN mkdir /uploads
COPY --from=upstream /localhost.crt /localhost.crt
COPY --from=upstream /localhost.key /localhost.key
COPY --from=builder /agnhost /agnhost
COPY --from=upstream /var/registry /var/registry
RUN ln -s agnhost agnhost-2
RUN adduser -u 1000 -D user-defined-in-image && \
    addgroup -g 50000 group-defined-in-image && \
    addgroup user-defined-in-image group-defined-in-image

LABEL commit_id="${KUBERNETES_COMMIT}" \
      git_url="https://github.com/kubernetes/kubernetes/tree/${KUBERNETES_COMMIT}/test/images/agnhost" \
      image_version="${AGNHOST_VERSION}"

ENTRYPOINT ["/agnhost"]
CMD ["pause"]
