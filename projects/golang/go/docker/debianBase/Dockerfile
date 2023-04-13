FROM buildpack-deps:bullseye-scm AS go-untar
ARG GOLANG_ARCHIVE_PATH
COPY $GOLANG_ARCHIVE_PATH /go-untar/
RUN tar -xvzf /go-untar/*.tar.gz

FROM buildpack-deps:bullseye-scm
RUN mkdir -p /usr/local/go
COPY --from=go-untar /go-untar/ /usr/local/go/
RUN cd /usr/local/go \
	&& ls -al


ENV GOPATH /go
ENV PATH /usr/local/go/bin:$GOPATH/bin:$PATH

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