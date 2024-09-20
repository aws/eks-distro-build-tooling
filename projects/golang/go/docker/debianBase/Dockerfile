FROM buildpack-deps:bullseye-scm AS go-untar
ARG GOLANG_ARCHIVE_PATH
RUN mkdir -p /usr/local/go
COPY $GOLANG_ARCHIVE_PATH /usr/local/
RUN cd /usr/local/ \
	&& tar -xvf *.tar.gz

FROM buildpack-deps:bullseye-scm
RUN mkdir -p /usr/local/go
COPY --from=go-untar /usr/local/go/ /usr/local/go/


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
