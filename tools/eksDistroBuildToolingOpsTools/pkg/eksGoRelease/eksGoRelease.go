package eksGoRelease

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
	"github.com/aws/eks-distro-build-tooling/tools/pkg/logger"
)

const (
	githubRepoUrl         = "https://github.com/%s/eks-distro-build-tooling.git"
	sOwner                = "rcrozean"
	prOwner               = "aws"
	projectPath           = "project/golang/go"
	filePathFmt           = "%s/%s/%s"
	patchesPathFmt        = "%s/%s/patches/%s"
	rpmSourcePathFmt      = "%s/%s/rpmbuild/SOURCE/%s"
	specPathFmt           = "%s/%s/rpmbuild/SPEC/%s"
	ArtifactPathFmt       = "https://distro.eks.amazonaws.com/golang-go%d.%d/release/%d/RPMS"
	readme                = "README.md"
	gitTag                = "GIT_TAG"
	ghRelease             = "RELEASE"
	patch2                = "0002-syscall-expose-IfInfomsg.X__ifi_pad-on-s390x.patch"
	patch3                = "0003-cmd-go-disable-Google-s-proxy-and-sumdb.patch"
	patch4                = "0004-cmd-link-use-gold-on-ARM-ARM64-only-if-gold-is-avail.patch"
	patch104              = "0104-add-method-to-skip-privd-tests-if-required.patch"
	fedora                = "fedora.go"
	gdbinit               = "golang-gdbinit"
	goSpec                = "golang.spec"
	minorReleaseBranchFmt = "eks-%s"
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
		ArtifactPath: fmt.Sprintf(ArtifactPathFmt, major, minor, release),
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

// Releasing new versions of Golang that don't exist in EKS Distro Build Tooling(https://github.com/aws/eks-distro-build-tooling/project/golang/go)
func (r Release) NewRelease(ctx context.Context) error {
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

	// Add files paths for new Go Minor Version
	// set up PR Creator handler
	prmOpts := &prManager.Opts{
		SourceOwner: "rcrozean",
		SourceRepo:  constants.EksdBuildToolingRepoName,
		PrRepo:      constants.EksdBuildToolingRepoName,
		PrRepoOwner: "rcrozean",
	}
	prm := prManager.New(retrier, githubClient, prmOpts)

	cprOpts := &prManager.CreateMultiCommitPrOpts{
		CommitBranch:    fmt.Sprintf("eks-%s", r.GoFullVersion()),
		BaseBranch:      "main",
		AuthorName:      "rcrozean",
		AuthorEmail:     "rcrozean@amazon.com",
		CommitMessage:   "commiting file %s",
		PrSubject:       fmt.Sprintf("Add path for new release of Golang: %s", r.GoSemver()),
		PrBranch:        "main",
		PrDescription:   "createTestBranch",
		DestFileGitPath: r.filePathsForNewRelease(),
		SourceFileBody:  r.fileContentsForNewRelease(),
	}

	url, err := prm.CreateMultiCommitPr(ctx, cprOpts)
	if err != nil {
		return fmt.Errorf("Create PR: %w", err)
	}
	logger.V(4).Info("New EKS Go %s version added to EKS Distro Build Tooling\n\nPR Open at: %s", r.GoSemver(), url)
	return nil
}

func (r *Release) filePathsForNewRelease() []string {
	var f []string
	// README.md, RELEASE, GIT_TAG
	f = append(f, fmt.Sprintf(filePathFmt, projectPath, r.GoMinorReleaseVersion(), readme))
	f = append(f, fmt.Sprintf(filePathFmt, projectPath, r.GoMinorReleaseVersion(), ghRelease))
	f = append(f, fmt.Sprintf(filePathFmt, projectPath, r.GoMinorReleaseVersion(), gitTag))
	// Init patch Files
	f = append(f, fmt.Sprintf(patchesPathFmt, projectPath, r.GoMinorReleaseVersion(), patch2))
	f = append(f, fmt.Sprintf(patchesPathFmt, projectPath, r.GoMinorReleaseVersion(), patch3))
	f = append(f, fmt.Sprintf(patchesPathFmt, projectPath, r.GoMinorReleaseVersion(), patch4))
	f = append(f, fmt.Sprintf(patchesPathFmt, projectPath, r.GoMinorReleaseVersion(), patch104))
	// Init rpmbuild/SOURCES
	f = append(f, fmt.Sprintf(rpmSourcePathFmt, projectPath, r.GoMinorReleaseVersion(), fedora))
	f = append(f, fmt.Sprintf(rpmSourcePathFmt, projectPath, r.GoMinorReleaseVersion(), gdbinit))
	// Init rpmbuild/SPECS
	f = append(f, fmt.Sprintf(specPathFmt, projectPath, r.GoMinorReleaseVersion(), goSpec))
	return f
}

func (r *Release) fileContentsForNewRelease() [][]byte {
	var f [][]byte
	var b []byte
	// README.md, RELEASE, GIT_TAG
	f = append(f, fmt.Append(b, "README"))
	f = append(f, fmt.Append(b, "0"))
	f = append(f, fmt.Appendf(b, "go%s", r.GoFullVersion()))
	// Init patch Files
	f = append(f, fmt.Append(b, "go%s", r.GoFullVersion()))
	f = append(f, fmt.Appendf(b, "go%s", r.GoFullVersion()))
	f = append(f, fmt.Appendf(b, "go%s", r.GoFullVersion()))
	f = append(f, fmt.Appendf(b, "go%s", r.GoFullVersion()))
	// Init rpmbuild/SOURCES
	f = append(f, fmt.Appendf(b, "//go:build rpm_crashtraceback\n// +build rpm_crashtraceback\n\npackage SOURCES\n\nfunc init() {\n	setTraceback(\"crash\")\n}\n"))
	f = append(f, fmt.Appendf(b, "add-auto-load-safe-path /usr/lib/golang/src/runtime/runtime-gdb.py\n"))
	// Init rpmbuild/SPECS
	f = append(f, fmt.Appendf(b, "go%s", r.GoFullVersion()))
	return f
}

// Releasing updates to versions of golang that exist in EKS Distro Build Tooling(https://github.com/aws/eks-distro-build-tooling/project/golang/go)
func (r Release) Update() error {
	fmt.Printf("EKS Go %s Updated in EKS Distro Build Tooling\n", r.GoSemver())
	return nil
}
