package constants

const (
	AwsOrgName                 = "aws"
	EksdBuildToolingRepoName   = "eks-distro-build-tooling"
	EksDistroBotName           = "eks-distro-bot"
	EksDistroPrBotName         = "eks-distro-pr-bot"
	EksGoSupportedVersionsPath = "projects/golang/go/MAINTAINED_EOL_VERSIONS"
	GolangOrgName              = "golang"
	GoRepoName                 = "go"
	OwnerWriteallReadOctal     = 0644
	SemverRegex                = `[0-9]+\.[0-9]+\.[0-9]+`
	AllowAllFailRespTemplate   = "%s only [%s](https://github.com/orgs/%s/people) org members may request may trigger automated issues. You can still create the issue manually."
)
