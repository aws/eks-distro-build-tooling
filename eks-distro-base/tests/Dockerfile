ARG BASE_IMAGE
ARG AL_TAG
FROM ${BASE_IMAGE} as base

FROM public.ecr.aws/amazonlinux/amazonlinux:${AL_TAG} as builder

WORKDIR /var/app

RUN yum install golang pkgconfig openssl-devel -y

RUN go mod init check
COPY *.go ./
RUN CGO_ENABLED=0 go build -o check-certs ./check_certs_timezone.go 
RUN CGO_ENABLED=1 go build -o check-cgo ./check_cgo.go 

FROM builder as git-builder

ARG GOPROXY
ENV GOPROXY=$GOPROXY

COPY --from=base /usr/lib64/pkgconfig/*.pc /usr/lib64/pkgconfig/
COPY --from=base /usr/include/git2.h /usr/include
COPY --from=base /usr/include/git2 /usr/include/git2
COPY --from=base /usr/lib64/libgit2* /usr/lib64
COPY --from=base /usr/lib64/libssh2* /usr/lib64
RUN ldd /usr/lib64/libgit2.so
RUN go get github.com/libgit2/git2go/v33
RUN CGO_ENABLED=1 go build -o check-git ./check_git.go 

FROM ${BASE_IMAGE} as check-base
COPY --from=builder /var/app/check-certs /bin
USER 65534
ENV TZ=Europe/Berlin

CMD ["/bin/check-certs"]

FROM ${BASE_IMAGE} as check-cgo
COPY --from=builder /var/app/check-cgo /bin

CMD ["/bin/check-cgo"]

FROM ${BASE_IMAGE} as check-git
COPY --from=git-builder /var/app/check-git /bin

CMD ["/bin/check-git"]

FROM ${BASE_IMAGE} as check-iptables-legacy

RUN ["update-alternatives", "--set", "iptables", "/usr/sbin/iptables-legacy"]
RUN ["update-alternatives", "--set", "ip6tables", "/usr/sbin/ip6tables-legacy"]

CMD ["iptables"]

FROM ${BASE_IMAGE} as check-iptables-nft

RUN ["update-alternatives", "--set", "iptables", "/usr/sbin/iptables-nft"]
RUN ["update-alternatives", "--set", "ip6tables", "/usr/sbin/ip6tables-nft"]

CMD ["iptables"]