package constants

const (
	AwsOrgName               = "aws"
	EksdBuildToolingRepoName = "eks-distro-build-tooling"
	EksDistroBotName         = "eks-distro-bot"
	EksDistroPrBotName       = "eks-distro-pr-bot"
	OwnerWriteallReadOctal   = 0644
	SemverRegex              = `[0-9]+\.[0-9]+\.[0-9]+`
	AllowAllFailRespTemplate = "@%s only [%s](https://github.com/orgs/%s/people) org members may request may trigger automated issues. You can still create the issue manually."
	GitTag                   = "GIT_TAG"
	Release                  = "RELEASE"
	Readme                   = "README.md"

	// Github Constants
	GolangOrgName = "golang"
	GoRepoName    = "go"
	GoRepoUrl     = "https://github.com/golang/go.git"

	// EKS Go Constants
	EksGoRepoUrl               = "https://github.com/%s/eks-distro-build-tooling.git"
	EksGoProjectPath           = "projects/golang/go"
	EksGoAmdBuildUrl           = "https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%d-%d-tooling-postsubmit"
	EksGoArmBuildUrl           = "https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%d-%d-ARM64-PROD-tooling-postsubmit"
	EksGoSupportedVersionsPath = "projects/golang/go/MAINTAINED_EOL_VERSIONS"
	EksGoArtifactUrl           = "https://distro.eks.amazonaws.com/golang-go%d.%d.%d/releases/%d/%s/%s/%s"
	EksGoTargzArtifactFmt      = "go%d.%d.%d.linux-%s.tar.gz"
	EksGoRpmArtifactFmt        = "golang-%d.%d.%d-%d.amzn2.eks.%s.rpm"
	EksGoNoarchRpmArtifactFmt  = "golang-src-%d.%d.%d-%d.amzn2.eks.%s.rpm"
)
