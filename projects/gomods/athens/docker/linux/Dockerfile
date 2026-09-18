ARG BASE_IMAGE
FROM $BASE_IMAGE

# Patch Alpine OS packages for known CVEs before publishing to AWS ECR.
# The upstream gomods/athens image lags the pinned Alpine stable repo, so this
# pulls patch-level security fixes.
RUN apk --no-cache upgrade
