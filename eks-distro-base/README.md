# eks-distro/base container image

## Standard Variant

The standard eks-distro-base defined by [Dockerfile.base](./Dockerfile.base) is the upstream AL2 image with the latest package updates.  The upstream AL2
image is not updated with every package change.  A daily periodic job runs [check_update.sh](./check_update.sh) which checks yum for new
security updates by running `yum check-update --security`.  If security updates are found, a new image is built and pushed to 
[ECR](https://gallery.ecr.aws/eks-distro-build-tooling/eks-distro-base).  PRs are automatically create to update the EKS_DISTRO_BASE_TAG_FILE 
file in this repo as well as [eks-distro](https://github.com/aws/eks-distro) and [eks-anywhere-build-tooling](https://github.com/aws/eks-anywhere-build-tooling).

The standard variant is currently the base image for EKS-D versions 1.18-1.21, but is not intended to be the base for future EKS-D versions or new container images.  
The minimal variants are now recommended where possible.

## Minimal Variants

The minimal image variants were introduced to decrease the landscape of potential security concerns in EKS-D/EKS-A base images.  The majority of container images
contain and are intended to only run a static golang binary.  These containers can typically use the [minimal-base](./Dockerfile.minimal-base) variant which, similar to upstream's
[Distroless](https://github.com/GoogleContainerTools/distroless) images contain the bare minimum package set which is tracked in [base](../eks-distro-minimal-packages/linux_amd64/base).

[minimal-base-iptables](./Dockerfile.minimal-base-iptables) is intended to be used as the base for kube-proxy in EKS-D in 1.22+ and currently in use as the base
for [kindnetd](https://github.com/aws/eks-anywhere-build-tooling/blob/main/projects/kubernetes-sigs/kind/images/kindnetd/Dockerfile) in the EKS-A kind node-image.  The list of packages
is tracked in [iptables](../eks-distro-minimal-packages/linux_amd64/iptables).

[minimal-base-glibc] is used as the base image for any image which contains golang binaries which are compiled with `CGO_ENABLED=1` or for containers which require other
standard linux dependencies, such as the iptables variant.  The list of packages
is tracked in [glibc](../eks-distro-minimal-packages/linux_amd64/glibc).

It is **strongly** recommended to create container images based on one of the minimal variants whenever possible.  Security updates are checked for daily for these variants just
like for the standard base.

### Design

The minimal variants are created using multistage builds and `yum --installroot` and `rpm --root` to install packages into `/newroot` which is copied in the final image based on `scratch`.
An opinionated approach is taken in deciding the final package set which make up these images.  In some cases, dependencies defined in the various packages' `rpm` config are explicitly excluded.
As an example, `systemd` is a dependency of `ebtables` in the iptables variant, but since the image(s) based on this variant are not actually running systemd, it is explicitly excluded from the final image, along with its dependencies.  
Similarly, `bash` does not exist in most of the minimal variants, however it is a dependency of `glibc` (and vice-versa), but 
it is also explicitly removed.  Packages like these are excluded by manually installing the rpm into the rpm database before running `yum install` for each of the desired packages.  There will be warnings when running
yum, but it will not install the excluded package or dependencies not required by other packages being installed.

Some packages depend on core utils (ex: gawk, grep, sed) during their rpm pre-install phase.  For these cases, the dependent packages are either explicitly installed ahead of time or allowed to be installed
with `yum install` for each of the desired packages.  These utilities are then removed before creating the final image.

The final image contains a rpm database created during the builder stage of the builds.  These rpm databases contain the list of packages which were either install via `yum` or `rpm` directly.
The rpm database is included to support common container scanning processes, including ECR's automated scanning.  The list of packages in each image is checked into to this repo and kept up
to date via periodic prow jobs.  These files can found at [eks-distro-minimal-packages](../eks-distro-minimal-packages) for both the linux/amd64 and linux/arm64 builds.

There are multiple approaches taken to getting the final list of RPMs that should be installed and how they are installed depending on the specific use case.

##**Recommended** 

When the desired executables are known, using the [install_binary](./scripts/install_binary) script is the easiest and best approach.  This approach uses `yum provides` to determine
the RPM which includes the desired executable, downloads and extracts the RPM and finally manually copies the specific executable (along with text files in `/etc` and `/usr/share` like licenses).
Once the executable has been copied to its final location, [`ldd`](https://man7.org/linux/man-pages/man1/ldd.1.html) is used to determine the specific dynamic library dependencies.  For each of these dependencies a similar process from above is followed to determine the 
needed RPM.  These RPMs are installed completely using [`rpm --root`](https://man7.org/linux/man-pages/man8/rpm.8.html) directly instead of `yum install` to avoid other dependencies getting pulled in.  This approach will usually result in the smallest possible image
with the shallowest CVE scope due to minimal number of included RPM packages.  All RPMs extracted for specific executables or installed for libraries are included in the final image's rpmdb.  
This approach is used in the [ebs-csi variant](./Dockerfile.minimal-base-csi-ebs) and most desired for any images
built outside of this repo.

When specific RPMs are desired, for example `iptables` which includes many different executables, [install_rpm](./scripts/install_rpm) can be used to tightly control the RPMs installed
in the final image.  This will require understanding the dependency tree of these RPMs since it does not use `yum install` which handles installing all necessary dependencies.  The upside to this
approach is being able to avoid installing packages like `systemd` or common tools needed like `coreutils` or `gawk` just to remove them afterwards to avoid its entire dependencies tree being pulled in and because they are unwanted in the final image.  This approach is used for the [iptables](./Dockerfile.minimal-base-iptables) and [nginx](Dockerfile.minimal-base-nginx) variants.

**Avoid if possible** If the final image is to include a large number of packages and the dependency tree is not easily defined [clean_install](./scripts/clean_install) can be used to install packages
along with their dependencies.  This approached is used for the [kind](./Dockerfile.minimal-base-kind) and [csi](./Dockerfile.minimal-base-csi) variants because their overall dependency tree is so large.
Take notice in the case of the `csi` image `systemd` is "fake" installed just to be removed.  This was a common pattern used across most variants when this was the primary installation method and should
continue to be used when necessary to avoid completely ballooning the scope of images.

### Validation and Tests

After each build there is a validation stage which uses `ldd` to validate that for each dynamic executable the final image contains the required libraries.  It also validates
there are no dangling symlinks to make sure missing expected files do not go unnoticed.

There is a set of VERY basic [tests](./tests/run_tests.sh) which use docker (and not run in CI) to perform the most minimal validations.  The most interesting ones relate to the
`git` and `iptables` variants where there are a number of expected executables and libraries.  There is no reason new, or existing, variants couldn't have more sophisticated tests...

### "API"

`CLEANUP_UNNECESSARY_FILES` can be exported in the Dockerfile to automatically remove files that may not be needed in the final image. This is used in a few different variants
to remove dangling symlinks due to RPMs not being fully installed.

`<rpm_name>_SCRIPTLET_REQS` can be exported in the Dockerfile for packages that require specific tools during the RPM scriptlet preinstall phase.  These tools, along with a default list defined in [eks-d-common](./scripts/eks-d-common) are symlinked into the the `installroot` (/newroot) so that when RPMs are installed the scripts should succeeded.  The build will catch
common failures here, but not all so pay close attention to the output when adding new RPMs or binaries to images.

### Creating new images

Creating new images based off minimal variants where new packages are necessary will require a multi-stage build using the builder images which are also pushed to [ECR](https://gallery.ecr.aws/eks-distro-build-tooling].
To ensure consistency and proper cleanup during install and removal of packages, the [scripts](./scripts) are added to `/usr/bin` and are used extensively throughout the variant Dockerfiles.

#### Examples

```
ARG BASE_IMAGE
ARG BUILDER_IMAGE
FROM ${BUILDER_IMAGE} as tar-builder

RUN set -x && \
    install_binary /usr/bin/tar && \
    cleanup "tar"

FROM ${BASE_IMAGE} as tar
COPY --from=tar-builder /newroot /
```

```
ARG BASE_IMAGE
ARG BUILDER_IMAGE
FROM ${BUILDER_IMAGE} as iptables-builder

RUN set -x && \
    install_rpm iptables && \
    cleanup "iptables"

FROM ${BASE_IMAGE} as iptables
COPY --from=iptables-builder /newroot /
```

```
ARG BASE_IMAGE
ARG BUILDER_IMAGE
FROM ${BUILDER_IMAGE} as iptables-builder

RUN set -x && \
    clean_install systemd true true && \
    clean_install iptables && \
    remove_package systemd true && \
    cleanup "iptables"

FROM ${BASE_IMAGE} as iptables
COPY --from=iptables-builder /newroot /
```

```
export LATEST_GLIBC_BASE_TAG=<latest_tag_from_ecr>
export IMAGE_TAG=<your_image_repo_tag>
buildctl \
    build \
    --frontend dockerfile.v0 \
    --opt platform=linux/amd64 \
    --opt build-arg:BASE_IMAGE=public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base-glibc:$LATEST_GLIBC_BASE_TAG \
    --opt build-arg:BUILDER_IMAGE=public.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base-glibc-builder:$LATEST_GLIBC_BASE_TAG \
    --progress plain \
    --local dockerfile=./ \
    --local context=. \
    --opt target=<target> \
    --output type=image,oci-mediatypes=true,name=$IMAGE_TAG,push=true
```

## Building locally

Building the eks-distro-base images locally requires `buildkitd` running and either a local registry or a publicly accessible registry, such as ECR.  To build the images using a local registry:

1. `docker run -d --name buildkitd --net host --privileged moby/buildkit:v0.9.0-rootless`
1. `docker run -d --name registry  --net host registry:2`
1. `export BUILDKIT_HOST=docker-container://buildkitd`
1. `export DATE_EPOCH=$(date "+%F-%s")`
    * used as the IMAGE_TAG
1. `IMAGE_REPO=localhost:5000 IMAGE_TAG=${DATE_EPOCH} make build -C eks-distro-base`
    * from the root of this repo
    * `build` target will only build the `linux/amd64` versions, you set `PLATFORMS=linux/amd64,linux/arm64` or run the `release` target to build both arch.
1. There are a few basic tests to validate the minimal base images.  If working on these image, please manually run these tests before creating a PR.
    * The tests require a folder with ssh keys and a private repo the user has access to to validate the git variant.
    * `export SSH_KEY_FOLDER=<ssh_key_folder>`
    * `export PRIVATE_REPO=<private_repo>`
    * `IMAGE_REPO=localhost:5000 IMAGE_TAG=${DATE_EPOCH} make minimal-base-test -C eks-distro-base`
1. To build AL22 based images pass `AL_TAG=2022` to the make call
1. To build a specific image based on an image published to [the EKS-D ECR](https://gallery.ecr.aws/eks-distro-build-tooling)
    * `BASE_IMAGE_REPO=public.ecr.aws/eks-distro-build-tooling IMAGE_REPO=localhost:5000 IMAGE_TAG=${DATE_EPOCH} make minimal-images-base-iptables -C eks-distro-base`   

There are additional flows that are run in prow.

1. Setting `JOB_TYPE` to `presubmit` or `postsubmit` will run the check for security updates flow.
1. To export the packages in each of the minimal images
    * `IMAGE_REPO=localhost:5000 IMAGE_TAG=${DATE_EPOCH} JOB_TYPE=postsubmit make export-minimal-images -C eks-distro-base`
1. To test automated PR creation workflow
    * `REPO_OWNER=<github_user> JOB_TYPE="presubmit" make create-pr -C eks-distro-base`
    * Note: this requires up additional setup locally.
