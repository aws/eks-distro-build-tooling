ARG BASE_IMAGE
FROM $BASE_IMAGE

# Patch Alpine OS packages for known CVEs before publishing to AWS ECR.
# Upstream agnhost tags are not rebuilt when Alpine ships security fixes.
RUN apk --no-cache upgrade
