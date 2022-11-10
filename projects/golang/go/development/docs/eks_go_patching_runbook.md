# EKS Go Developer Documentation

Documentation for EKS Go developers and those looking to extend and work with the EKS Go build and distribution systems.

## Contents
1. [Adding a Go minor version to EKS Go](#adding-a-go-minor-version-to-eks-go)
1. [Updating an EKS Go minor version to use a new upstream Go patch version](#new-patch-versions)

## Adding a Go Minor Version to EKS Go
When a new Golang minor version is released EKS Go will need to track and build that version.
This guide lays out the steps to add a new Go minor version to EKS Go.

This work breaks down into a few steps:

1. [setup the project structure in EKS Distro Build Tooling](#setup-project-structure)
1. [setup the Golang RPM spec in EKS Distro Build Tooling](#golang-rpm-spec)
1. [configure EKS Go prow pre-submits in EKS Distro Prow Jobs](#prow-jobs-pre-submits)
1. [configure EKS Go prow post-submits in EKS Distro Prow Jobs](#prow-jobs-post-submits)

### Setup Project Structure

First, we need to set up the new Go minor version project structure, mirroring the other Go minor versions supported by EKS Go.
You can use the [the helper script](../scripts/setup_golang_minor_version.sh) to set up the initial structure.
For example, to set up Go `1.19` starting at the Git tag `go1.19.2`, 
you would invoke the following command in a clone of EKS Distro Build Tooling and commit the results:

```shell
../scripts/setup_golang_minor_version.sh 1.19 go1.19.2
```

This helper script will create:
- folder structure
- `GIT_TAG` file, which defines which upstream Git tag we're pinning our build to
- `RELEASE` file, which defines which EKS Go release we're on and will trigger an EKS Go release on modification
- `README.md` for the given version, with the initial information, including Prow build badges etc.

Now that you've set up this initial project structure, we will move on the setting up the EKS Go RPM spec for the given version.

### Golang RPM Spec for EKS Go
Now that we've got a project structure, we need to obtain an [an RPM Spec](https://rpm-software-management.github.io/rpm/manual/spec.html) for the target Go version.

EKS Go bases our RPM spec off of the upstream Amazon Linux or Fedora Golang RPM specs. 
The best way to obtain a base RPMs for a given version of Go is to pull the upstream RPM from their package source, 
unpack the RPM to obtain the spec file, and adapt the spec to build EKS Go at the appropriate path and tag, and apply our custom patches.

For example, to obtain a SPEC file for Go `1.19`, do the following:
1. Identify the proper RPM to base our EKS Go build on
    1. identify the Amazon Linux 2 Golang RPM for the given version using `yum list —show-duplicates golang` on an Amazon Linux 2 machine.
    1. If Amazon Linux does not yet support the given version of Golang, instead use [the Fedora yum repo](https://packages.fedoraproject.org/pkgs/golang/golang/) to find an appropriate RPM for the given Golang version.

1. Download and unpack the target RPM:
   1. download the target RPM from the package repo and unpack it. The command below will download the target RPM and unpack it into the `~/rpmbuild` directory.
     The `spec` file will be output to `~/rpmbuild/SPECS` and any sources (such as test files and patches) will be
     output to `~/rpmbuild/SOURCES`.
   ```shell
   yumdownloader --source golang-1.16.15-1.amzn2.0.1
   rpm -ivh golang-1.16.15-1.amzn2.0.1.src.rpm
   ```
   2. Copy the source files from `~/rpmbuild/SOURCES` to `projects/golang/go/$VERSION/rpmbuild/SOURCES`
   1. Copy the spec file from `~rpmbuild/SPECS` to `projects/golang/go/$VERSION/rpmbuild/SPECS`.

1. Update the upstream Spec file with EKS Go conventions 
   1. EKS Go uses a specific RPM Release string to identify itself. 
Find [the `RELEASE` string in the unpacked spec file](https://github.com/aws/eks-distro-build-tooling/blob/main/projects/golang/go/1.18/rpmbuild/SPECS/golang.spec#L121)
and modify it to use our format:
   ```shell
   Release:        %{?_buildid}%{?dist}.eks
   ```
   2. EKS Go builds from cloned upstream source at build-time, rather than a pre-packaged source included with the RPM. 
      This means we need to modify the RPM setup directive to target the right directory. 
      Modify [the `autosetup` directive to follow the pattern we use in our other RPM spec files.](https://github.com/aws/eks-distro-build-tooling/blob/main/projects/golang/go/1.19/rpmbuild/SPECS/golang.spec#L293) 
      Specifically, ensure we're targeting the source directory of the format `go-go%{go_version}`.

1. Add EKS Go specific patches

   Next, add any additional required patch files to the `SOURCES` directory, and [update the modified spec file to apply them](https://github.com/aws/eks-distro-build-tooling/blob/main/projects/golang/go/1.19/rpmbuild/SPECS/golang.spec#L165).
   Golang RPM spec files after Go 1.16 use the RPM directive [`autosetup`](https://github.com/aws/eks-distro-build-tooling/blob/main/projects/golang/go/1.19/rpmbuild/SPECS/golang.spec#L293), so all you need to do to apply a patch at build time is define it as a Patch source in the spec.
   
   EKS Go currently requires one custom patch for each Go version, above and beyond the security patches. 
   This patch allows us to skip specific Golang standard library tests in certain circumstances, such as skipping privilleged tests which call `mount` when we're building the RPM in a container[^1]. 
   You can find [the Go 1.19 version of that patch here](../../1.19/patches/0104-add-method-to-skip-privd-tests-if-required.patch). 
   
   

1. Document your work in the RPM spec changelog

   Add [a changelog entry to the RPM spec](https://github.com/aws/eks-distro-build-tooling/blob/main/projects/golang/go/1.16/rpmbuild/SPECS/golang.spec#L558) outlining the changes made to the RPM spec

1. Commit the spec file, sources, and any other changes, and push to your fork of EKS Distro build tooling, and open a work-in-progress PR with a hold on it.
In the next step we'll set up prow jobs to will let us test all of this work by running a prow pre-submit against this PR.

Now that we've set up the project structure, sourced and customized a Golang Spec file, and applied our custom patches, we need to test!
The easiest way to do this is to set up the EKS Go pre-submits for the given version and let them do the testing. 
That way, you can simply commit your new EKS Go minor version and create a PR to initiate the entire RPM spec build and test.

### Prow Jobs: Pre-submits
EKS Go is built in Prow. For each new Go version we need to set up Presubmits to build the Go version. 

EKS Go prow jobs can be found in [the EKS Distro Prow Jobs repository](https://github.com/aws/eks-distro-prow-jobs/tree/main/templater/jobs/presubmit/eks-distro-build-tooling).

In order to add a pre-submit for testing new EKS Go minor versions, copy an existing pre-submit, such as [this one for EKS Go `1.19`](https://github.com/aws/eks-distro-prow-jobs/blob/main/templater/jobs/presubmit/eks-distro-build-tooling/eks-distro-base-presubmits-golang-1-19.yaml),
and replace all occurrences of `1.19` with the new minor version of Go you wish to support (e.g. `1.20`).

Once you've added a template for this new job, [use the standard prow make commands](https://github.com/aws/eks-distro-prow-jobs/blob/main/docs/prowjobs.md) to generate the job yaml from the template (e.g. `make -C templater prow-jobs`).

Once this pre-submit is merged into EKS Distro Prow jobs, it will run against the PR you created in the previous step, attempting to build the RPM spec file, applying the patches, and doing a dry-run push to S3 for the resulting RPMs. 
Debug any failures of this prowjob to ensure that the spec file is correct and the project is building as expected. For some common issues, see [the debugging FAQ below](#debugging-eks-go-builds)

### Prow Jobs: Post-submits
EKS Go is built and tested in Prow. For each new Go version we need to set up prow post-submits to build the Go version.

EKS Go prow jobs can be find in the [EKS Distro Prow Jobs repository](https://github.com/aws/eks-distro-prow-jobs/tree/main/templater/jobs/postsubmit/eks-distro-build-tooling)

Each minor version of EKS Go currently has four post-submits:
- [ARM64 post-submit](https://github.com/aws/eks-distro-prow-jobs/blob/main/templater/jobs/postsubmit/eks-distro-build-tooling/golang-1.18-ARM64-postsubmits.yaml)
- [AMD64 post-submit](https://github.com/aws/eks-distro-prow-jobs/blob/main/templater/jobs/postsubmit/eks-distro-build-tooling/golang-1.18-postsubmits.yaml)
- [AMD64 prod release post-submit](https://github.com/aws/eks-distro-prow-jobs/blob/main/templater/jobs/postsubmit/eks-distro-build-tooling/golang-1.18-PROD-postsubmits.yaml)
- [ARM64 prod release post-submit](https://github.com/aws/eks-distro-prow-jobs/blob/main/templater/jobs/postsubmit/eks-distro-build-tooling/golang-1.18-ARM64-PROD-postsubmits.yaml)

Make a copy of each of the types of post-submits and change their names and target versions to match the new minor version being added to EKS Go.

## New Patch Versions
When a new Golang patch version for a currently in-support Go version is released,
EKS Go needs to be updated in order to build that version. This is a fairly straight-forward process, 
only requiring you to bump the tracked version in the `GIT_TAG` file of the given Go minor version project directory and update the `go_patch` value in the RPM spec.

For example, if you wanted to update EKS Go to track `go1.19.3`, you would:
- update the `GIT_TAG` file in `1.19` to use this new tag.
- update the `go_patch` value in the `1.19` RPM spec to use the new patch version, `3`.
- cut a PR and monitor the presubmits to ensure that the build passed successfully and the artifacts were properly generated. 
- merge the PR and monitor the post-submits to ensure that the post-submit builds also pass

## FAQ
### Debugging EKS Go RPM Builds
#### Go Tests Fail with Permissions Denied Errors
Check that the [skip-privileged-tests](https://github.com/aws/eks-distro-build-tooling/blob/main/projects/golang/go/1.19/patches/0104-add-method-to-skip-privd-tests-if-required.patch) patch are applied correctly. 
Any calls to `mount` that the tests make inside a containerized environment will fail, so we ensure that we skip them.

Check any net new tests for privileged actions like calls to `mount` and evaluate if these should be skipped or addressed in some other way.

#### Patches Don't Apply Cleanly When Building the RPM
Ensure you haven't just copied a patch file from an older version of EKS Go. 
You want to generate a patch for that specific version by checking out the target tag, cherry-picking the commit you want, and generating a patch with `git format-patch -1 $COMMIT_HASH`.
A copied patch file from a previous version may not apply cleanly.

#### "No such file or directory" when executing the RPM spec Prep or Autosetup directives
Ensure that you've adjusted the RPM spec [as outlined above](#golang-rpm-spec-for-eks-go) to run the `autosetup` directive in the correct directory, nameley ` go-go%{go_version}`

### Notes
[^1]: This is required because of the way that EKS Go builds and tests Golang in an unprivileged container running in our prow cluster.
There are a few Go standard library tests which call `mount` as part of the test.
The [`mount` syscall](https://man7.org/linux/man-pages/man2/mount.2.html), which attaches a specified filesystem, requires highly elevated privileges, such as [the CAP_SYS_ADMIN capability](https://man7.org/linux/man-pages/man7/capabilities.7.html).
This level of permission if not appropriate or secure in a containerized environment, as it would allow unfettered modification of the host system by the container, and we do not provide our test containers with this level of privilege. 
Therefore, we apply a patch that allows us to skip the few tests that require `mount` calls in our CI environment.