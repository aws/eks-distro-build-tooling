ARG BASE_IMAGE
ARG AL_TAG
ARG BUILDER_IMAGE=public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base:${AL_TAG}
FROM ${BASE_IMAGE} as base

FROM public.ecr.aws/eks-distro-build-tooling/golang:1.18-gcc-al${AL_TAG} as builder

WORKDIR /var/app

RUN yum install openssl-devel -y

RUN go mod init check
COPY *.go ./
RUN CGO_ENABLED=0 go build -o check-certs ./check_certs_timezone.go 
RUN CGO_ENABLED=1 go build -o check-cgo ./check_cgo.go 

FROM ${BASE_IMAGE} as check-base
COPY --from=builder /var/app/check-certs /bin
USER 65534
ENV TZ=Europe/Berlin

CMD ["/bin/check-certs"]

FROM ${BASE_IMAGE} as check-cgo
COPY --from=builder /var/app/check-cgo /bin

CMD ["/bin/check-cgo"]

FROM ${BASE_IMAGE} as check-iptables-legacy

CMD ["iptables"]

FROM ${BASE_IMAGE} as check-iptables-nft

RUN ["update-alternatives", "--set", "iptables", "/usr/sbin/iptables-nft"]
RUN ["update-alternatives", "--set", "ip6tables", "/usr/sbin/ip6tables-nft"]

CMD ["iptables"]

FROM public.ecr.aws/eks-distro-build-tooling/golang:1.20-al${AL_TAG} as iptables-wrapper-tests-builder

COPY iptables-wrappers /iptables-wrappers
RUN cd /iptables-wrappers && \
    make build-tests

FROM ${BASE_IMAGE} as check-iptables-wrapper

COPY --from=iptables-wrapper-tests-builder /iptables-wrappers/bin/tests /
RUN ["update-alternatives", "--set", "iptables", "/usr/sbin/iptables-wrapper"]

CMD ["iptables"]

FROM builder as git-builder

ARG GOPROXY
ENV GOPROXY=$GOPROXY

COPY --from=base /usr/lib64/pkgconfig/*.pc /usr/lib64/pkgconfig/
COPY --from=base /usr/include/git2.h /usr/include
COPY --from=base /usr/include/git2 /usr/include/git2
COPY --from=base /usr/lib64/libgit2* /usr/lib64
COPY --from=base /usr/lib64/libssh2* /usr/lib64
RUN ldd /usr/lib64/libgit2.so
RUN --mount=type=secret,id=netrc,target=/root/.netrc \
    go get github.com/libgit2/git2go/v33
RUN --mount=type=secret,id=netrc,target=/root/.netrc \
    CGO_ENABLED=1 go build -o check-git ./check_git.go 

FROM ${BASE_IMAGE} as check-git
COPY --from=git-builder /var/app/check-git /bin

CMD ["/bin/check-git"]
