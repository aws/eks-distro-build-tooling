ARG BASE_IMAGE #gcr.io/k8s-prow/<image>:v20200924-369a496323 

FROM $BASE_IMAGE

# Patch Alpine OS packages for known CVEs before publishing to AWS ECR.
# Upstream Prow images lag the pinned Alpine stable repo, so this pulls
# patch-level security fixes.
RUN apk --no-cache upgrade
