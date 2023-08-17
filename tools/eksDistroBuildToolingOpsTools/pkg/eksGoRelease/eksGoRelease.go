package eksGoRelease

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/go-git/go-git/v5/plumbing/transport/http"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/pkg/logger"
)

const (
	githubRepoUrl               = "https://github.com/%s/eks-distro-build-tooling.git"
	sOwner                      = "rcrozean"
	prOwner                     = "aws"
	projectPath                 = "projects/golang/go"
	filePathFmt                 = "%s/%s/%s"
	rpmSourcePathFmt            = "%s/%s/rpmbuild/SOURCE/%s"
	specPathFmt                 = "%s/%s/rpmbuild/SPEC/%s"
	ArtifactPathFmt             = "https://distro.eks.amazonaws.com/golang-go%d.%d/release/%d/RPMS"
	readme                      = "README.md"
	readmeFmt                   = "# EKS Golang %s\n\nCurrent Release: `%d`\n\nTracking Tag: `%s`\n\nArtifacts: https://distro.eks.amazonaws.com/golang-go%s/releases/%d/RPMS\n\n### ARM64 Builds\n[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%s-ARM64-PROD-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%%2Feks-distro-build-tooling&type=postsubmit)\n\n### AMD64 Builds\n[![Build status](https://prow.eks.amazonaws.com/badge.svg?jobs=golang-%s-tooling-postsubmit)](https://prow.eks.amazonaws.com/?repo=aws%%2Feks-distro-build-tooling&type=postsubmit)\n\n### Patches\nThe patches in `./patches` include relevant utility fixes for go `%s`.\n\n### Spec\nThe RPM spec file in `./rpmbuild/SPECS` is sourced from the go %s SRPM available on Fedora, and modified to include the relevant patches and build the `%s` source.\n"
	gitTag                      = "GIT_TAG"
	ghRelease                   = "RELEASE"
	fedora                      = "fedora.go"
	gdbinit                     = "golang-gdbinit"
	goSpec                      = "golang.spec"
	minorReleaseBranchFmt       = "eks-%s"
	newMinorVersionCommitMsgFmt = "Init new Go Minor Version %s files."
)

func NewEksGoReleaseObject(versionString string) (*Release, error) {
	splitVersion := strings.Split(versionString, ".")
	major, err := strconv.Atoi(splitVersion[0])
	if err != nil {
		return nil, err
	}

	minor, err := strconv.Atoi(splitVersion[1])
	if err != nil {
		return nil, err
	}

	patch, err := strconv.Atoi(splitVersion[2])
	if err != nil {
		return nil, err
	}

	return &Release{
		Major:        major,
		Minor:        minor,
		Patch:        patch,
		Release:      -1, // TODO: Figure out if we need this for the EKSGo Releases or if this is just best generated on the fly when cloning the EKS DISTRO BUILD TOOLING repo
		ArtifactPath: fmt.Sprintf(ArtifactPathFmt, major, minor, -1),
	}, nil
}

type Release struct {
	Major        int
	Minor        int
	Patch        int
	Release      int
	ArtifactPath string
}

func (r Release) GoReleaseBranch() string {
	return fmt.Sprintf("release-branch.go%d.%d", r.Major, r.Minor)
}

func (r Release) GoMajorVersion() int {
	return r.Major
}

func (r Release) GoMinorVersion() int {
	return r.Minor
}

func (r Release) GoPatchVersion() int {
	return r.Patch
}

func (r Release) ReleaseNumber() int {
	return r.Release
}

func (r Release) EksGoArtifacts() string {
	return r.ArtifactPath
}

func (r Release) EksGoReleaseFullVersion() string {
	return fmt.Sprintf("v%d.%d.%d-%d", r.Major, r.Minor, r.Patch, r.Release)
}

func (r Release) GoFullVersion() string {
	return fmt.Sprintf("%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) GoMinorReleaseVersion() string {
	return fmt.Sprintf("%d.%d", r.Major, r.Minor)
}

func (r Release) GoSemver() string {
	return fmt.Sprintf("v%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) Equals(release Release) bool {
	if r.Major != release.GoMajorVersion() {
		logger.V(4).Info("Major version not equal", "self Major", r.Major, "compare Major", release.GoMajorVersion())
		return false
	}
	if r.Minor != release.GoMinorVersion() {
		logger.V(4).Info("Minor version not equal", "self Minor", r.Minor, "compare Minor", release.GoMinorVersion())
		return false
	}
	if r.Patch != release.GoPatchVersion() {
		logger.V(4).Info("Patch version not equal", "self Patch", r.Patch, "compare Patch", release.GoPatchVersion())
		return false
	}
	if r.Release != release.ReleaseNumber() {
		logger.V(4).Info("Release version not equal", "self Release", r.Release, "compare Release", release.ReleaseNumber())
		return false
	}
	return true
}

// Releasing new versions of Golang that don't exist in EKS Distro Build Tooling(https://github.com/aws/eks-distro-build-tooling/projects/golang/go)
func (r Release) NewMinorRelease(ctx context.Context) error {
	r.Release = 0
	// Setup Github Client
	// retrier := retrier.New(time.Second*380, retrier.WithBackoffFactor(1.5), retrier.WithMaxRetries(15, time.Second*30))

	token, err := github.GetGithubToken()
	if err != nil {
		logger.V(4).Error(err, "no github token found")
		return fmt.Errorf("getting Github PAT from environment at variable %s: %v", github.PersonalAccessTokenEnvVar, err)
	}
	// githubClient, err := github.NewClient(ctx, token)
	//if err != nil {
	//	return fmt.Errorf("setting up Github client: %v", err)
	//}

	// Creating git client in memory and clone 'eks-distro-build-tooling
	gClient := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(fmt.Sprintf(githubRepoUrl, sOwner)), git.WithAuth(&http.BasicAuth{Username: sOwner, Password: token}))
	gClient.Clone(ctx)
	if err != nil {
		logger.Error(err, "Cloning repo")
		return err
	}

	if err := gClient.Pull(ctx, "main"); err != nil {
		logger.Error(err, "git pull main")
		return err
	}
	// Create new branch
	if err := gClient.Branch(r.EksGoReleaseFullVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseFullVersion())
		return err
	}

	var b []byte
	// Add files for new minor versions of golang.
	// Add README.md
	readmePath := fmt.Sprintf(filePathFmt, projectPath, r.GoMinorReleaseVersion(), readme)
	readmeContent := generateReadme(r.GoMinorReleaseVersion(), r.GoSemver(), r.ReleaseNumber())
	fmt.Println(readmeContent)
	if err := gClient.CreateFile(readmePath, b); err != nil {
		logger.Error(err, "Adding README.md", "path", readmePath, "content", readmeContent)
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		logger.Error(err, "git add", "file", readmePath)
		return err
	}

	// Add RELEASE
	releasePath := fmt.Sprintf(filePathFmt, projectPath, r.GoMinorReleaseVersion(), ghRelease)
	releaseContent := fmt.Append(b, r.ReleaseNumber())
	if err := gClient.CreateFile(releasePath, b); err != nil {
		logger.Error(err, "Adding RELEASE", "path", releasePath, "content", releaseContent)
		return err
	}
	if err := gClient.Add(releasePath); err != nil {
		logger.Error(err, "git add", "file", releasePath)
		return err
	}

	// Add GIT_TAG
	gittagPath := fmt.Sprintf(filePathFmt, projectPath, r.GoMinorReleaseVersion(), gitTag)
	gittagContent := fmt.Appendf(b, "go%s", r.GoSemver())
	if err := gClient.CreateFile(gittagPath, gittagContent); err != nil {
		logger.Error(err, "Adding GIT_TAG", "path", gittagPath, "content", gittagContent)
		return err
	}
	if err := gClient.Add(gittagPath); err != nil {
		logger.Error(err, "git add", "file", gittagPath)
		return err
	}

	// Add fedora.go
	fedoraFilePath := fmt.Sprintf(rpmSourcePathFmt, projectPath, r.GoMinorReleaseVersion(), fedora)
	fedoraContent := fmt.Append(b, "temp")
	if err := gClient.CreateFile(fedoraFilePath, fedoraContent); err != nil {
		logger.Error(err, "Adding fedora file", "path", fedoraFilePath)
	}
	if err := gClient.Add(fedoraFilePath); err != nil {
		logger.Error(err, "git add", "file", fedoraFilePath)
		return err
	}

	// Add golang-gdbinit
	gdbinitFilePath := fmt.Sprintf(rpmSourcePathFmt, projectPath, r.GoMinorReleaseVersion(), gdbinit)
	gdbinitContent := fmt.Append(b, "temp")
	if err := gClient.CreateFile(gdbinitFilePath, gdbinitContent); err != nil {
		logger.Error(err, "Adding fedora file", "path", gdbinitFilePath)
	}
	if err := gClient.Add(gdbinitFilePath); err != nil {
		logger.Error(err, "git add", "file", gdbinitFilePath)
		return err
	}

	// Commit files
	commitMsg := fmt.Sprintf(newMinorVersionCommitMsgFmt, r.GoMinorReleaseVersion())
	if err := gClient.Commit(commitMsg); err != nil {
		logger.Error(err, "git commit", "message", commitMsg)
		return err
	}

	// Push to forked repository
	if err := gClient.Push(ctx); err != nil {
		logger.Error(err, "git push")
		return err
	}

	logger.V(3).Info("Release EKS Go Minor Vresion", "EKS Go Version", r.EksGoReleaseFullVersion())
	return nil
}

func generateReadme(goMinorVersion, gitTag string, release int) string {
	return fmt.Sprintf(readmeFmt, goMinorVersion, release, gitTag, goMinorVersion, release, goMinorVersion, goMinorVersion, goMinorVersion, goMinorVersion, gitTag)
}
