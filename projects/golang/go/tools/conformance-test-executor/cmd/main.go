package cmd

import (
	"fmt"

	"github.com/aws/eks-distro-build-tooling/golang/conformance-test-executor/pkg/prowJobs"
)

func main() {
	// Construct EKS Go conformance-test execution post-submit
	// This should:
	// - rebuild the builder-base with the dev release and push to a secondary ECR
	// - set the image for this prow job to that builder-base
	// - execute the `main-postsubmit` with `rebuild-all` set to `true`

	prowJobsOpts := prowJobs.GenerateConformanceTestsProwJobsOptions{
		TestRoleArn:                 "",
		ArtifactsBucket:             "",
		ControlPlaneInstanceProfile: "",
		NodeInstanceProfile:         "",
		KopsStateStore:              "",
		ImageRepo:                   "",
		DockerConfig:                "",
		RuntimeImage:                "",
	}
	conformanceTestProwJob := prowJobs.GenerateConformanceTestProwJob("", prowJobsOpts)
	fmt.Println(string(conformanceTestProwJob))

	//TODO: Apply the job to the cluster to run
}