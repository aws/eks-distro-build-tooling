# Prometheus container image

This builds the [Prometheus](https://github.com/prometheus/prometheus) linux-amd64 image and uploads to ECR for use in our Prow cluster.

## Steps to update builds

Following are the steps to update the version of Prometheus getting built.
1. Figure out the new commit hash on the [Prometheus](https://github.com/prometheus/prometheus) repo that you want to update to.
2. Update the GIT_COMMIT file with the selected commit hash.
3. Upstream [Dockerfile](https://github.com/prometheus/prometheus/blob/master/Dockerfile) uses `latest` tag for the base image. Please be mindful and verify the current `latest` base image can build the selected git commit.