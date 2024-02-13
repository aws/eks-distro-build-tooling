package eksGoRelease

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	minorReleaseBranchFmt = "eks-%s"
	filePathFmt           = "%s/%s/%s"
	patchesPathFmt        = "%s/%s/patches/%s"
	rpmSourcePathFmt      = "%s/%s/rpmbuild/SOURCES/%s"
	specPathFmt           = "%s/%s/rpmbuild/SPECS/%s"
	readmeFmtPath         = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/versionReadmeFmt.txt"
	newReleaseFile        = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/newRelease.txt"
	fedoraFile            = "fedora.go"
	gdbinitFile           = "golang-gdbinit"
	goSpecFile            = "golang.spec"
)

func generateVersionReadme(readmeFmt string, r *Release) string {
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

	title := r.GoMinorVersion()
	curRelease := r.ReleaseNumber()
	trackTag := r.GoFullVersion()
	armBuild := r.EksGoArmBuild()
	amdBuild := r.EksGoAmdBuild()
	patch := r.GoMinorVersion()
	fSpec := r.GoMinorVersion()
	sSpec := r.GoFullVersion()
	return fmt.Sprintf(readmeFmt, title, curRelease, trackTag, artifactTable, armBuild, amdBuild, patch, fSpec, sSpec)
}

// Update golang/go/<VERSION>/README.md
func updateVersionReadme(gClient git.Client, r *Release) error {
	readmePath := fmt.Sprintf(filePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.Readme)
	readmeFmt, err := gClient.ReadFile(readmeFmtPath)
	if err != nil {
		logger.Error(err, "Reading version README fmt file")
		return err
	}

	readmeContent := generateVersionReadme(readmeFmt, r)
	logger.V(4).Info("Update version README.md", "path", readmePath)
	logger.V(6).Info("Update version README.md", "content", readmeContent)
	if err := gClient.ModifyFile(readmePath, []byte(readmeContent)); err != nil {
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		return err
	}
	return nil
}

func updateSupportedVersionsProjectReadme(fc *string, r *Release) string {
	slO := "## Supported Versions\nEKS currently supports the following Golang versions:"
	slN := fmt.Sprintf("## Supported Versions\nEKS currently supports the following Golang versions:\n- [`v%s`](./%s/GIT_TAG)", r.GoMinorVersion(), r.GoMinorVersion())
	*fc = strings.Replace(*fc, slO, slN, 1)

	// EKS Go supports n-1 versions outside upstream. Ie if upstream supprot 1.22, 1.21, eks go supports 1.20
	dv := fmt.Sprintf("%d.%d", r.Major, r.Minor-3)
	slO = fmt.Sprintf("\n- [`v%s`](./%s/GIT_TAG)", dv, dv)
	slN = "\n"
	*fc = strings.Replace(*fc, slO, slN, 1)

	return *fc
}

func updateDeprecatedVersionsProjectReadme(fc *string, r *Release) string {
	// EKS Go supports n-1 versions outside upstream. Ie if upstream supprot 1.22, 1.21, eks go supports 1.20
	// dv represents this as the most recent deprecated version
	dv := fmt.Sprintf("%d.%d", r.Major, r.Minor-3)

	// EKS Go supports n-1 versions outside upstream. Ie if upstream supprot 1.22, 1.21, eks go supports 1.20
	// lsv represents this as the last supported version
	lsv := fmt.Sprintf("%d.%d", r.Major, r.Minor-2)

	dlO := "## Deprecated Versions"
	dlN := fmt.Sprintf("## Deprecated Versions\n- [`v%s`](./%s/GIT_TAG)", dv, dv)

	*fc = strings.Replace(*fc, dlO, dlN, 1)

	dnO := "**Due to the increased security risk this poses, it is HIGHLY recommended that users of `EKS-GO v1.15 - v1.17` update to a supported version of EKS-Go (v1.18+) as soon as possible.**"
	dnN := fmt.Sprintf("**Due to the increased security risk this poses, it is HIGHLY recommended that users of `EKS-GO v1.15 - v%s` update to a supported version of EKS-Go (v%s+) as soon as possible.**", dv, lsv)

	*fc = strings.Replace(*fc, dnO, dnN, 1)
	return *fc
}

// Update projects/golang/go/README.md
func updateProjectReadme(gClient git.Client, r *Release) error {
	readmePath := fmt.Sprintf("%s/%s", constants.EksGoProjectPath, constants.Readme)
	readmeContent, err := gClient.ReadFile(readmePath)
	if err != nil {
		logger.Error(err, "Reading project README file")
		return err
	}

	readmeContent = updateSupportedVersionsProjectReadme(&readmeContent, r)
	readmeContent = updateDeprecatedVersionsProjectReadme(&readmeContent, r)
	logger.V(4).Info("Update version README.md", "path", readmePath)
	logger.V(6).Info("Update version README.md", "content", readmeContent)
	if err := gClient.ModifyFile(readmePath, []byte(readmeContent)); err != nil {
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		return err
	}
	return nil
}

func bumpRelease(gClient git.Client, r *Release) error {
	// Get Current EKS Go Release Version from repo and increment
	releasePath := fmt.Sprintf(filePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.Release)

	content, err := gClient.ReadFile(releasePath)
	if err != nil {
		if !strings.Contains(err.Error(), "file not found") {
			logger.Error(err, "Reading file", "file", releasePath)
			return err
		}
		r.Release = 0
	} else {
		// Check if there is a new line character at the end of the file, if so take all but the newline
		if content[len(content)-1:] == "\n" {
			content = content[0 : len(content)-1]
		}
		cr, err := strconv.Atoi(content)
		if err != nil {
			logger.Error(err, "Converting current release to int")
			return err
		}
		// Increment release
		r.Release = cr + 1
	}
	logger.V(4).Info("release bumped to", "release", r.Release)

	return nil
}

func updateRelease(gClient git.Client, r *Release) error {
	logger.V(4).Info("gClient", "client", gClient)
	// update RELEASE
	releasePath := fmt.Sprintf(filePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.Release)
	releaseContent := fmt.Sprintf("%d", r.ReleaseNumber())
	logger.V(4).Info("Update RELEASE", "path", releasePath, "content", releaseContent)
	if err := gClient.ModifyFile(releasePath, []byte(releaseContent)); err != nil {
		if !strings.Contains(err.Error(), "file not found") {
			return err
		}
		releaseContent = fmt.Sprintf("%d", 0)
		if err := gClient.CreateFile(releasePath, []byte(releaseContent)); err != nil {
			return err
		}
	}
	if err := gClient.Add(releasePath); err != nil {
		logger.Error(err, "git add", "file", releasePath)
		return err
	}

	return nil
}

func updateGitTag(gClient git.Client, r *Release) error {
	// update GIT_TAG
	gittagPath := fmt.Sprintf(filePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.GitTag)
	gittagContent := fmt.Sprintf("go%s", r.GoFullVersion())
	logger.V(4).Info("Update GIT_TAG", "path", gittagPath, "content", gittagContent)
	if err := gClient.ModifyFile(gittagPath, []byte(gittagContent)); err != nil {
		return err
	}
	if err := gClient.Add(gittagPath); err != nil {
		logger.Error(err, "git add", "file", gittagPath)
		return err
	}

	return nil
}

func updateGoSpecPatchVersion(fc *string, r *Release) string {
	gpO := fmt.Sprintf("%%global go_patch %d", r.PatchVersion()-1)
	gpN := fmt.Sprintf("%%global go_patch %d", r.PatchVersion())

	return strings.Replace(*fc, gpO, gpN, 1)
}

// TODO: Fix logic to apply previous patches, cherry pick fix, and create patch file
func createPatchFile(ctx context.Context, r *Release, gClient git.Client, golangClient git.Client, commit string) error {
	// Attempt patch generation if it fails, skip updating gospec with new patch number
	// Clone https://github.com/golang/go
	if err := golangClient.Clone(ctx); err != nil {
		logger.Error(err, "git clone", "repo", constants.GoRepoUrl)
		return err
	}

	if err := golangClient.Branch(r.GoReleaseBranch()); err != nil {
		logger.Error(err, "git branch", "branch name", r.GoReleaseBranch(), "repo", constants.GoRepoUrl, "client", golangClient)
		return err
	}

	// TODO: Apply patches current patches in <Version>/patches/

	// TODO: cherry pick commit string

	// TODO: Format-patch the last commit which will be the chrrypick commit

	// TODO: Copy patch file to EKS Go patch folder

	return nil
}

func updateGoSpec(gClient git.Client, r *Release) error {
	// update golang.spec
	goSpecPath := fmt.Sprintf(specPathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), goSpecFile)
	goSpecContent, err := gClient.ReadFile(goSpecPath)
	if err != nil {
		logger.Error(err, "Reading spec.golang", "file", goSpecPath)
		return err
	}
	goSpecContent = updateGoSpecPatchVersion(&goSpecContent, r)
	logger.V(4).Info("Update golang.spec", "path", goSpecPath, "content", goSpecContent)
	if err := gClient.ModifyFile(goSpecPath, []byte(goSpecContent)); err != nil {
		return err
	}

	if err := gClient.Add(goSpecPath); err != nil {
		logger.Error(err, "git add", "file", goSpecPath)
		return err
	}

	return nil
}

func addTempFilesForNewMinorVersion(gClient git.Client, r *Release) error {
	// Add golang.spec
	specFilePath := fmt.Sprintf(rpmSourcePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), goSpecFile)
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
	gdbinitFilePath := fmt.Sprintf(rpmSourcePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), gdbinitFile)
	if err := gClient.CreateFile(gdbinitFilePath, []byte(newReleaseContent)); err != nil {
		logger.Error(err, "Adding fedora file", "path", gdbinitFilePath)
		return err
	}
	if err := gClient.Add(gdbinitFilePath); err != nil {
		logger.Error(err, "git add", "file", gdbinitFilePath)
		return err
	}

	// Add fedora.go
	fedoraFilePath := fmt.Sprintf(rpmSourcePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), fedoraFile)
	if err := gClient.CreateFile(fedoraFilePath, []byte(newReleaseContent)); err != nil {
		logger.Error(err, "Adding fedora file", "path", fedoraFilePath)
		return err
	}
	if err := gClient.Add(fedoraFilePath); err != nil {
		logger.Error(err, "git add", "file", fedoraFilePath)
		return err
	}

	return nil
}

func createReleasePR(ctx context.Context, dryrun bool, r *Release, ghUser github.GitHubUser, gClient git.Client, prSubject, prDescription, commitMsg, commitBranch string) error {
	if dryrun {
		logger.V(3).Info("running in dryrun mode no pr created")
		return nil
	}
	retrier := retrier.New(time.Second*380, retrier.WithBackoffFactor(1.5), retrier.WithMaxRetries(15, time.Second*30))

	githubClient, err := github.NewClient(ctx, ghUser.Token())
	if err != nil {
		return fmt.Errorf("setting up Github client: %v", err)
	}

	// Commit files
	// set up PR Creator handler
	prmOpts := &prManager.Opts{
		SourceOwner: ghUser.User(),
		SourceRepo:  constants.EksdBuildToolingRepoName,
		PrRepo:      constants.EksdBuildToolingRepoName,
		PrRepoOwner: constants.AwsOrgName,
	}
	prm := prManager.New(retrier, githubClient, prmOpts)

	prOpts := &prManager.CreatePrOpts{
		CommitBranch:  commitBranch,
		BaseBranch:    "main",
		AuthorName:    ghUser.User(),
		AuthorEmail:   ghUser.Email(),
		PrSubject:     prSubject,
		PrBranch:      "main",
		PrDescription: prDescription,
	}

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

	logger.V(3).Info("Update EKS Go Version", "EKS Go Version", r.EksGoReleaseVersion(), "PR", prUrl)
	return nil
}
