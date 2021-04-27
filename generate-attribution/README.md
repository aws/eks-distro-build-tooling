# generate-attribution

generate-attribution is used to generate the ATTRIBUTION.txt files for each of the dependency projects that make up eks-d.  

### Usage
The builder-base assumes generate-attribution is on the PATH for usage during the eks-d build process.  If trying to run the build process locally:

1. npm install
    * requires node >= 15
2. ln -s $(pwd)/generate-attribution /usr/local/bin/generate-attribution


### Arguments
This process depends on [go-licenses](https://github.com/google/go-licenses) having run and generated the csv file of dependencies as well as copied the all licenses into a LICENSES folder.  A json file of the ouput from `go list -json` is also required.

Example run of dependencies

1. go list -deps=true -json ./... | jq -s ''  > "_out/attribution/go-deps.json"
2. go-licenses save --force ./coredns.go --save_path="_out/LICENSES"
3. go-licenses csv ./coredns.go > "_out/attribution/go-license.csv"

Argument parsing is primative and positional.  The ordering follows:

1. root module name, ex: github.com/coredns/coredns
    * this is the name of the dependency as it shows in the go-license.csv file
2. project directory
    * directory must contain a GIT_TAG file with the root module version
3. go lang version, ex: go1.15.6
    * the std go library needs to be included in the ATTRIBUTION.txt.  The license is pulled from upstream based on the passed in version tag
4. project output directory containing the following directory structure

```
outputDir
|
└───LICENSES
│   └───dep
│       │   LICENSE
│       │   ...
│   
└───attribution
    │   go-license.csv
    │   go-deps.json
```
     
An ATTRIBUTION.txt file will be created in the outputDir/attribution directory.  A summary.txt will also be created with a high level breakdown of the different license types.

### Run tests
Tests cases were created from the generated files in eks-d.

1. `./tests/run-tests.sh`
