package constants

const (
	AwsOrgName                 = "aws"
	EksdBuildToolingRepoName   = "eks-distro-build-tooling"
	EksDistroBotName           = "eks-distro-bot"
	EksDistroPrBotName         = "eks-distro-pr-bot"
	OwnerWriteallReadOctal     = 0644
	SemverRegex                = `[0-9]+\.[0-9]+\.[0-9]+`
	AllowAllFailRespTemplate   = "@%s only [%s](https://github.com/orgs/%s/people) org members may request may trigger automated issues. You can still create the issue manually."
	GitTag                     = "GIT_TAG"
	ReleaseTag                 = "RELEASE"
	Readme                     = "README.md"
)
