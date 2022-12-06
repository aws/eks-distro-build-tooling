FROM buildpack-deps:bullseye-scm

ARG GOLANG_ARCHIVE_PATH

ADD $GOLANG_ARCHIVE_PATH /usr/local

ENV GOPATH /go
ENV PATH /usr/local/go/bin:$PATH
ENV PATH $GOPATH/bin:$PATH
ENV GOLANG_VERSION GOLANG_VERSION

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
	; \
	rm -rf /var/lib/apt/lists/* \
	; \
	mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH" \
	; \
	go version

WORKDIR $GOPATH