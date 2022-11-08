# EKS Go Developer Documentation

## Set up EKS Go to build a new Go minor version
When a new Golang minor version is released EKS Go will need to track and build that version.
This section lays out the steps required to add a new Go minor version to EKS Go. 

### Setup Project Structure

Set up the project structure, mirroring the other versions we support.
This can be done by invoking [the helper script](../scripts/setup_golang_minor_version.sh).
For example, to set up Go 1.19 starting at the Git tag go1.19.2, 
you would invoke the following command and commit the results:

```shell
../scripts/setup_golang_minor_version.sh 1.19 go1.19.2
```

This helper script will create:
- folder structure
- `GIT_TAG` file
- `RELEASE` file
- `README.md` for the given version

### Golang RPM Spec
Now that we've got a project structure, we need to obtain an [an RPM Spec](https://rpm-software-management.github.io/rpm/manual/spec.html) for the target Go version.

EKS Go bases our RPM spec off of the upstream Amazon Linux or Fedora Golang RPM specs. 
The best way to obtain these RPMs for a given version of Go is to pull the upstream RPM from their package source, 
unpack the RPM to obtain the spec file, and adapt the spec to build EKS Go at the appropriate path and tag.

For example, to obtain a SPEC file for Go 1.19, do the following:
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

1. Update the Upstream Spec file with EKS Go conventions 
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
   This patch allows us to skip specific Golang standard library tests in certain circumstances, such as skipping privilleged tests which call `mount` when we're building the RPM in a container. 
   You can find [the GO 1.19 version of that patch here](../../1.19/patches/0104-add-method-to-skip-privd-tests-if-required.patch). 

Ok, now that we've set up the project structure, sourced and customized a Golang Spec file, and applied our custom patches, we need to test!
The easiest way to do this is to set up the EKS Go pre-submits for the given version and let them do the testing. 
That way, you can simply commit your new EKS Go minor version and create a PR to initiate the entire RPM spec build and test.

### Prow Jobs: Pre-submits
EKS Go is built in Prow. For each new Go version we need to set up Presubmits to build the Go version.

### Prow Jobs: Post-submits
EKS Go is built and tested in Prow. For each new Go version we need to set up prow post-submits to build the Go version.

## New Patch Versions
When a new Golang patch version for a currently in-support Go version is released,
EKS Go needs to be updated in order to build that version. This is a fairly straight-forward process, 
only requiring you to bump the tracked version in the `GIT_TAG` file of the given Go minor version project directory.

For example, if you wanted to update EKS Go to track `go1.19.3`, you would update the `GIT_TAG` file in `1.19` to use this new tag.
You would then monitor the presubmits to ensure that the build passed successfully and the artifacts were properly generated. 
Once the monitored presubmits have passed and the git tag bump was merged, you would monitor the post-submits to ensure that the post-submit builds also passed. 
