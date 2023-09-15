
package constants

const (
  //Github Constants
	GolangOrgName                    = "golang"
	GoRepoName                       = "go"
  GoRepoUrl                        = "https://github.com/golang/go.git"
  
  //EKS Go Constants 
  EksGoRepoUrl                     = "https://github.com/%s/eks-distro-build-tooling.git"
  EksGoProjectPath                 = "projects/golang/go"
  EksGoAmdBuildUrl                 = "https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%d-%d-tooling-postsubmit"
  EksGoArmBuildUrl                 = "https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%d-%d-ARM64-PROD-tooling-postsubmit"
	EksGoSupportedVersionsPath       = "projects/golang/go/MAINTAINED_EOL_VERSIONS"
	EksGoArtifactUrl                 = "https://distro.eks.amazonaws.com/golang-go%d.%d.%d/release/%d/%s/%s/%s"
  EksGoTargzArtifactFmt            = "go%d.%d.%d.linux-%s.tar.gz"
  EksGoRpmArtifactFmt              = "golang-%d.%d.%d-%d.amzn2.eks.%s.rpm"
)
