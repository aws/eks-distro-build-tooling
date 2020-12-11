# builder-base container image

This image is used to build other jobs, and serves as a base image for prow jobs


## Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `AWS_REGION` | `us-west-2` | The AWS region where your ECR repository is hosted. |
| `BASE_IMAGE` | `amazonlinux:2` | The base image for this Dockerfile.
| `TARGETARCH` | `amd64` | The architecture for the image to be built on. Support values: `amd64`, `arm64` |
| `TARGETOS` | `linux` | The target operating system for the builds. |
| `GOLANG_DOWNLOAD_URL` | `https://golang.org/dl` | The URL to download the Go binaries. |
| `GOLANG_VERSION` | See Makefile | The version of Go to install. |
| `GOLANG_CHECKSUM` | See Makefile  | The checksum to verify the version of Go. |
| `BUILDKIT_VERSION` | See Makefile  | The version of Buildkit to install. |
| `BUILDKIT_CHECKSUM` | See Makefile | The checksum to verify the version of the Build Kit. |

## Building with BoringSSL

BoringSSL is replacement for Go Crypto. BoringSSL provides support for FIPS 140-2 validated cryptography which is needed to meet compliance in some situations.

```bash
make \
  GOLANG_DOWNLOAD_URL=https://go-boringcrypto.storage.googleapis.com \
  GOLANG_VERSION=1.15.5b5 \
  GOLANG_CHECKSUM=9c97488137f1f560b3fff0d8a2a9c45d2de8790fb8952a42b46cc4633528fc48 \
  docker
```

## Fetching the Checksums

```bash
# fetch from standard golang url
./scripts/checksums.sh 1.15.5

# fetch from borirngssl builds
./scripts/checksums.sh 1.15.5b https://go-boringcrypto.storage.googleapis.com
```
