package constants

type githubRepo struct {
	Owner      string
	Repository string
}

const (
	aws = "aws"
	//repository names
	eksd             = "eks-distro"
	eksdBuildTooling = "eks-distro-build-tooling"
	eksdProwJobs     = "eks-distro-prow-jobs"
)
