package eksGoRelease

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/go-git/go-git/v5/plumbing/transport/http"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	basePathFmt                 = "%s/%s/%s"
	patchesPathFmt              = "%s/%s/patches/%s"
	rpmSourcePathFmt            = "%s/%s/rpmbuild/SOURCES/%s"
	specPathFmt                 = "%s/%s/rpmbuild/SPECS/%s"
	readmeFmtPath               = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/readmeFmt.txt"
	newReleaseFile              = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/newRelease.txt"
	fedoraFile                  = "fedora.go"
	gdbinitFile                 = "golang-gdbinit"
	goSpecFile                  = "golang.spec"
	minorReleaseBranchFmt       = "eks-%s"
	newMinorVersionCommitMsgFmt = "Init new Go Minor Version %s files."
)

func NewEksGoReleaseObject(versionString string) (*Release, error) {
	splitVersion := strings.Split(versionString, ".")
	major, err := strconv.Atoi(splitVersion[0])
	if err != nil {
		return nil, fmt.Errorf("parsing major version: %v", err)
	}

	minor, err := strconv.Atoi(splitVersion[1])
	if err != nil {
		return nil, fmt.Errorf("parsing minor version: %v", err)
	}

	patch, err := strconv.Atoi(splitVersion[2])
	if err != nil {
		return nil, fmt.Errorf("parsing patch version: %v", err)
	}

	return &Release{
		Major: major,
		Minor: minor,
		Patch: patch,
	}, nil
}

type Release struct {
	Major   int
	Minor   int
	Patch   int
	Release int
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

// "https://distro.eks.amazonaws.com/golang-go%d.%d.%d/release/%d/%s/%s/%s"
func (r Release) EksGoArtifacts(arch string) (string, string, string) {
	var artifact string // artifact = "golang-%d.%d.%d-%d.amzn2.eks.%s.rpm"
	var urlFmt string   // artifact = "golang-%d.%d.%d-%d.amzn2.eks.%s.rpm"

	switch arch {
	case "x86_64", "aarch64":
		artifact = fmt.Sprintf(constants.EksGoRpmArtifactFmt, r.Major, r.Minor, r.Patch, r.Release, arch)
		urlFmt = fmt.Sprintf(constants.EksGoArtifactUrl, r.Major, r.Minor, r.Patch, r.Release, arch, "RPMS", arch)
	case "noarch":
		artifact = fmt.Sprintf(constants.EksGoRpmArtifactFmt, r.Major, r.Minor, r.Patch, r.Release, arch)
		urlFmt = fmt.Sprintf(constants.EksGoArtifactUrl, r.Major, r.Minor, r.Patch, r.Release, "x86_64", "RPMS", arch)
	case "amd64", "arm64":
		artifact = fmt.Sprintf(constants.EksGoTargzArtifactFmt, r.Major, r.Minor, r.Patch, arch)
		urlFmt = fmt.Sprintf(constants.EksGoArtifactUrl, r.Major, r.Minor, r.Patch, r.Release, "archives", "linux", arch)
	}

	return artifact, fmt.Sprintf("%s.sha256", artifact), urlFmt
}

func (r Release) EksGoAmdBuild() string {
	return fmt.Sprintf(constants.EksGoAmdBuildUrl, r.Major, r.Minor)
}

func (r Release) EksGoArmBuild() string {
	return fmt.Sprintf(constants.EksGoArmBuildUrl, r.Major, r.Minor)
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
func (r Release) NewMinorRelease(ctx context.Context, dryrun bool, email, user string) error {
	// Setup Github Client
	retrier := retrier.New(time.Second*380, retrier.WithBackoffFactor(1.5), retrier.WithMaxRetries(15, time.Second*30))

	token, err := github.GetGithubToken()
	if err != nil {
		logger.V(4).Error(err, "no github token found")
		return fmt.Errorf("getting Github PAT from environment at variable %s: %v", github.PersonalAccessTokenEnvVar, err)
	}

	githubClient, err := github.NewClient(ctx, token)
	if err != nil {
		return fmt.Errorf("setting up Github client: %v", err)
	}

	// Creating git client in memory and clone 'eks-distro-build-tooling
	forkUrl := fmt.Sprintf(constants.EksGoRepoUrl, user)
	gClient := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(forkUrl), git.WithAuth(&http.BasicAuth{Username: user, Password: token}))
	if err := gClient.Clone(ctx); err != nil {
		logger.Error(err, "Cloning repo")
		return err
	}
	// Create new branch
	if err := gClient.Branch(r.EksGoReleaseFullVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseFullVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Add files for new minor versions of golang.
	// Add README.md
	readmePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), constants.Readme)
	readmeFmt, err := gClient.ReadFile(readmeFmtPath)
	if err != nil {
		logger.Error(err, "Reading README fmt file")
		return err
	}

	readmeContent := generateReadme(readmeFmt, r)

	logger.V(4).Info("Create README.md", "path", readmePath, "content", readmeContent)
	if err := gClient.CreateFile(readmePath, []byte(readmeContent)); err != nil {
		logger.Error(err, "Adding README.md", "path", readmePath, "content", readmeContent)
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		logger.Error(err, "git add", "file", readmePath)
		return err
	}

	// Add RELEASE
	releasePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), constants.ReleaseTag)
	releaseContent := fmt.Sprintf("%d", r.ReleaseNumber())
	if err := gClient.CreateFile(releasePath, []byte(releaseContent)); err != nil {
		logger.Error(err, "Adding RELEASE", "path", releasePath, "content", releaseContent)
		return err
	}
	if err := gClient.Add(releasePath); err != nil {
		logger.Error(err, "git add", "file", releasePath)
		return err
	}

	// Add GIT_TAG
	gittagPath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), constants.GitTag)
	gittagContent := fmt.Sprintf("go%s", r.GoFullVersion())
	if err := gClient.CreateFile(gittagPath, []byte(gittagContent)); err != nil {
		logger.Error(err, "Adding GIT_TAG", "path", gittagPath, "content", gittagContent)
		return err
	}
	if err := gClient.Add(gittagPath); err != nil {
		logger.Error(err, "git add", "file", gittagPath)
		return err
	}

	// Add golang.spec
	specFilePath := fmt.Sprintf(rpmSourcePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), goSpecFile)
	rf, err := gClient.ReadFile(newReleaseFile)
	if err != nil {
		logger.Error(err, "Reading newRelease.txt file")
		return err
	}

	newReleaseContent := rf
	if err := gClient.CreateFile(specFilePath, []byte(newReleaseContent)); err != nil {
		logger.Error(err, "Adding fedora file", "path", specFilePath)
		return err
	}
	if err := gClient.Add(specFilePath); err != nil {
		logger.Error(err, "git add", "file", specFilePath)
		return err
	}

	// Add golang-gdbinit
	gdbinitFilePath := fmt.Sprintf(rpmSourcePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), gdbinitFile)
	if err := gClient.CreateFile(gdbinitFilePath, []byte(newReleaseContent)); err != nil {
		logger.Error(err, "Adding fedora file", "path", gdbinitFilePath)
		return err
	}
	if err := gClient.Add(gdbinitFilePath); err != nil {
		logger.Error(err, "git add", "file", gdbinitFilePath)
		return err
	}

	// Add fedora.go
	fedoraFilePath := fmt.Sprintf(rpmSourcePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), fedoraFile)
	if err := gClient.CreateFile(fedoraFilePath, []byte(newReleaseContent)); err != nil {
		logger.Error(err, "Adding fedora file", "path", fedoraFilePath)
		return err
	}
	if err := gClient.Add(fedoraFilePath); err != nil {
		logger.Error(err, "git add", "file", fedoraFilePath)
		return err
	}

	// Add temp file in <version>/patches/
	patchesFilePath := fmt.Sprintf(patchesPathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), "temp")
	patchesContent := []byte("Copy")
	if err := gClient.CreateFile(patchesFilePath, patchesContent); err != nil {
		logger.Error(err, "Adding patches folder path", "path", patchesFilePath)
		return err
	}
	if err := gClient.Add(patchesFilePath); err != nil {
		logger.Error(err, "git add", "file", patchesFilePath)
		return err
	}

	// Commit files
	// Add files paths for new Go Minor Version
	// set up PR Creator handler
	prmOpts := &prManager.Opts{
		SourceOwner: user,
		SourceRepo:  constants.EksdBuildToolingRepoName,
		PrRepo:      constants.EksdBuildToolingRepoName,
		PrRepoOwner: constants.AwsOrgName,
	}
	prm := prManager.New(retrier, githubClient, prmOpts)

	prOpts := &prManager.CreatePrOpts{
		CommitBranch:  r.EksGoReleaseFullVersion(),
		BaseBranch:    "main",
		AuthorName:    user,
		AuthorEmail:   email,
		PrSubject:     fmt.Sprintf("Add path for new release of Golang: %s", r.GoSemver()),
		PrBranch:      "main",
		PrDescription: fmt.Sprintf("Init Go Minor Version: %s", r.GoMinorReleaseVersion()),
	}

	createReleasePR(ctx, r, gClient, dryrun, prm, prOpts)

	return nil
}

func generateReadme(readmeFmt string, r Release) string {
	/* Format generated for the readme follows:
	 *  ----------------------------------------
	 *  # EKS Golang <title>
	 *
	 *  Current Release: `<curRelease>`
	 *
	 *  Tracking Tag: `<trackTag>`
	 *
	 *  ### Artifacts:
	 *  |Arch|Artifact|sha|
	 *  |:---:|:---:|:---:|
	 *  |noarch|[%s](%s)|[%s](%s)|
	 *  |x86_64|[%s](%s)|[%s](%s)|
	 *  |aarch64|[%s](%s)|[%s](%s)|
	 *  |arm64.tar.gz|[%s](%s)|[%s](%s)|
	 *  |amd64.tar.gz|[%s](%s)|[%s](%s)|
	 *
	 *  ### ARM64 Builds
	 *  [![Build status](<armBuild>)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)
	 *
	 *  ### AMD64 Builds
	 *  [![Build status](<amdBuild>)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)
	 *
	 *  ### Patches
	 *  The patches in `./patches` include relevant utility fixes for go `<patch>`.
	 *
	 *  ### Spec
	 *  The RPM spec file in `./rpmbuild/SPECS` is sourced from the go <fSpec> SRPM available on Fedora, and modified to include the relevant patches and build the `go<sSpec>` source.
	 *
	 */
	eksGoArches := [...]string{"noarch", "x86_64", "aarch64", "arm64", "amd64"}
	artifactTable := ""
	for _, a := range eksGoArches {
		artifact, sha, url := r.EksGoArtifacts(a)
		artifactTable = artifactTable + fmt.Sprintf("|%s|[%s](%s)|[%s](%s)|\n", a, artifact, fmt.Sprintf("%s/%s", url, artifact), sha, fmt.Sprintf("%s/%s", url, sha))
	}

	fmt.Println(readmeFmt)
	title := r.GoMinorReleaseVersion()
	curRelease := r.ReleaseNumber()
	trackTag := r.GoFullVersion()
	armBuild := r.EksGoArmBuild()
	amdBuild := r.EksGoAmdBuild()
	patch := r.GoMinorReleaseVersion()
	fSpec := r.GoMinorReleaseVersion()
	sSpec := r.GoMinorReleaseVersion()
	return fmt.Sprintf(readmeFmt, title, curRelease, trackTag, artifactTable, armBuild, amdBuild, patch, fSpec, sSpec)
}

func updateGoSpecPatchVersion(fc *string, r Release) string {
	gpO := fmt.Sprintf("%%global go_patch %d", r.GoPatchVersion()-1)
	gpN := fmt.Sprintf("%%global go_patch %d", r.GoPatchVersion())

	return strings.Replace(*fc, gpO, gpN, 1)
}

func addPatchGoSpec(fc *string, r Release, patch string) string {
	return ""
}

func createReleasePR(ctx context.Context, r Release, gClient git.Client, dryrun bool, prm *prManager.PrCreator, prOpts *prManager.CreatePrOpts) error {
	if !dryrun {
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

		prUrl, err := prm.CreatePr(ctx, prOpts)
		if err != nil {
			// This shouldn't be an breaking error at this point the PR is not open but the changes
			// have been pushed and can be created manually.
			logger.Error(err, "github client create pr failed. Create PR manually from github webclient", "create pr opts", prOpts)
			prUrl = ""
		}

		logger.V(3).Info("Update EKS Go Version", "EKS Go Version", r.EksGoReleaseFullVersion(), "PR", prUrl)
	}
	return nil
}
