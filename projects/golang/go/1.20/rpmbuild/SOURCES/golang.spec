Generate [an RPM Spec](https://rpm-software-management.github.io/rpm/manual/spec.html) for the target Go version.

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

