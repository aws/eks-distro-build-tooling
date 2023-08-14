## EKS Go Release Tool
The EKS Go Release Tool is intended as a home for all automation used to release, update, and patch EKS Go with new releases.
It is intended to eventually replace eksGoTool.

### Using the Tool
use `eksGoRelese --help` for up-to-date usage

The tool has an `release` command which creates new minor version release structure and files.
The tool has an `update` command which updates upstream supported versions for new patch releases.

The `release` command accepts a EKS Go release version via the flag `eksGoRelease`. 
For example to release a new version of eksGo `1.21.0`
you would run the following:

```shell
eksGoRelease release --eksGoReleases=1.21.0
```

The `update` command accepts a comma-seperated list of EKS Go release versions via the flag `eksGoRelease`. 
Updates are run for each given release version. For example, to run updaters for the EKS Go release `1.20.2` & `1.19.3`, 
you would run the following:

```shell
eksGoRelease update --eksGoReleases=1.20.2,1.19.3
```

### Building the Tool
To build the Consumer Updater binary, run the build make target `make build-eksGoRelease`
from the root of the Ops Tool. This will produce a binary in `tools/eksDistroBuildToolingOpsTools/bin/$GOOS/$GOARCH/eksGoRelease`.
