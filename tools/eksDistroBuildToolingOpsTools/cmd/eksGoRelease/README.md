## EKS Go Release Tool
The EKS Go Release Tool is intended as a home for all automation used to release, update, and patch EKS Go with new releases.
It is intended to eventually replace eksGoTool.

### Using the Tool
`make build-eksGoRelease` generates the binary
`eksGoRelease --help` for up-to-date usage
```
Tools for updating and releasing EKS Go

Usage:
  eksGoRelease [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  new         Release a new minor version of EKS Go
  patch       Cherrypick a patch to versions of EKS Go
  release     Release EKS Go
  update      Update new patch versions of EKS Go

Flags:
  -d, --dryrun                  run without creating PR
      --eksGoReleases strings   EKS Go releases to update
  -e, --email string            github email for git functions
  -h, --help                    help for eksGoRelease
  -u, --user string             github username for git functions
  -v, --verbosity int           Set the log level verbosity
```
#### Commands:
`new` Create repo structure for a new minor version of EKS Go

`release` Release EKS Go version(s)

`update` Update new patch version(s) of EKS Go

Work In Progress:
`patch` Cherrypick a patch to version(s) of EKS Go


```shell
eksGoRelease new --eksGoReleases=1.21.0
```

The `update` command accepts a comma-seperated list of EKS Go release versions via the flag `eksGoRelease`. 
Updates are run for each given release version. For example, to run updaters for the EKS Go release `1.20.2` & `1.19.3`, 
```shell
eksGoRelease update --eksGoReleases=1.20.2,1.19.3
```


The `release` command accepts a comma-seperated list of EKS Go release versions via the flag `eksGoRelease`. 
This command is to be run after post-submits and builds pass. This command updates the README and when merged 
runs the prowjob triggering the sns message.
```shell
eksGoRelease release --eksGoReleases=1.20.2,1.19.3
```

### Building the Tool
To build the Consumer Updater binary, run the build make target `make build-eksGoRelease`
from the root of the Ops Tool. This will produce a binary in `tools/eksDistroBuildToolingOpsTools/bin/$GOOS/$GOARCH/eksGoRelease`.
