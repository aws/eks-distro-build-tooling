## New Minor Versions
When a new Golang minor version is released, EKS Go will need to track and build that version.
This section lays out the steps required to add a new Go version to EKS Go.

### Folder Structure

Set up the folder structure for the given version, mirroring the other versions we support. 
This can be done by invoking [the helper script](../scripts/setup_golang_minor_version.sh).
For example, if you wanted to set up a folder structure for Go 1.19 starting at the Git tag go1.19.2, 
you would invoke the following command:

```shell
../scripts/setup_golang_minor_version.sh 1.19 go1.19.2
```

This helper script will create the folder structure and needed files for the EKS Golang minor version and 
populate an initial README. Commit this folder structure and proceed to the next setups.

### Golang RPM Spec
Set up an RPM spec to build the given EKS Go version. 

EKS Go uses the upstream Amazon Linux and Fedora RPM spec files as a base for our spec files. 
The best way to obtain these RPMs for a given version of Go is to pull the upstream RPM from their package source, 
unpack the RPM to obtain the spec, and then modify and test the spec to build EKS Go and the appropriate path and tag.

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
