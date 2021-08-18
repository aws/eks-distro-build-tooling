ARG BASE_IMAGE

FROM golang as builder

WORKDIR /var/app

COPY *.go ./
RUN go mod init check
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

RUN ["update-alternatives", "--set", "iptables", "/usr/sbin/iptables-legacy"]
RUN ["update-alternatives", "--set", "ip6tables", "/usr/sbin/ip6tables-legacy"]

CMD ["iptables"]

FROM ${BASE_IMAGE} as check-iptables-nft

RUN ["update-alternatives", "--set", "iptables", "/usr/sbin/iptables-nft"]
RUN ["update-alternatives", "--set", "ip6tables", "/usr/sbin/ip6tables-nft"]

CMD ["iptables"]