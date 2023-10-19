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
	basePathFmt           = "%s/%s/%s"
	patchesPathFmt        = "%s/%s/patches/%s"
	rpmSourcePathFmt      = "%s/%s/rpmbuild/SOURCES/%s"
	specPathFmt           = "%s/%s/rpmbuild/SPECS/%s"
	readmeFmtPath         = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/readmeFmt.txt"
	newReleaseFile        = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/newRelease.txt"
	fedoraFile            = "fedora.go"
	gdbinitFile           = "golang-gdbinit"
	goSpecFile            = "golang.spec"
)

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
	title := r.GoMinorVersion()
	curRelease := r.ReleaseNumber()
	trackTag := r.GoFullVersion()
	armBuild := r.EksGoArmBuild()
	amdBuild := r.EksGoAmdBuild()
	patch := r.GoMinorVersion()
	fSpec := r.GoMinorVersion()
	sSpec := r.GoMinorVersion()
	return fmt.Sprintf(readmeFmt, title, curRelease, trackTag, artifactTable, armBuild, amdBuild, patch, fSpec, sSpec)
}

func updateReadme(gClient git.Client, r *Release) error {
	// Update README.md
	readmePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.Readme)
	readmeFmt, err := gClient.ReadFile(readmeFmtPath)
	if err != nil {
		logger.Error(err, "Reading README fmt file")
		return err
	}

	readmeContent := generateReadme(readmeFmt, *r)
	logger.V(4).Info("Update README.md", "path", readmePath, "content", readmeContent)
	if err := gClient.ModifyFile(readmePath, []byte(readmeContent)); err != nil {
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		return err
	}
	return nil
}

func bumpRelease(gClient git.Client, r *Release) error {
	files, err := gClient.ReadFiles("projects/golang/go/1.21")
	if err != nil {
		return err
	}
	for n, f := range files {
		logger.V(4).Info("golang version 1.21 files", "file", n, "content", f)
	}

	// Get Current EKS Go Release Version from repo and increment
	releasePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.ReleaseTag)

	content, err := gClient.ReadFile(releasePath)
	if err != nil {
		logger.Error(err, "Reading file", "file", releasePath)
		return err
	}
	// We need to check there isn't a \n character if there is we only take the first value
	if len(content) > 1 {
		content = content[0:1]
	}
	cr, err := strconv.Atoi(content)
	if err != nil {
		logger.Error(err, "Converting current release to int")
		return err
	}
	// Increment release
	r.Release = cr + 1

	return nil
}

func updateRelease(gClient git.Client, r *Release) error {
	logger.V(4).Info("gClient", "client", gClient)
	// update RELEASE
	releasePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.ReleaseTag)
	releaseContent := fmt.Sprintf("%d", r.ReleaseNumber())
	logger.V(4).Info("Update RELEASE", "path", releasePath, "content", releaseContent)
	if err := gClient.ModifyFile(releasePath, []byte(releaseContent)); err != nil {
		return err
	}
	if err := gClient.Add(releasePath); err != nil {
		logger.Error(err, "git add", "file", releasePath)
		return err
	}

	return nil
}

func updateGitTag(gClient git.Client, r *Release) error {
	// update GIT_TAG
	gittagPath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.GitTag)
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

func updateGoSpecPatchVersion(fc *string, r Release) string {
	gpO := fmt.Sprintf("%%global go_patch %d", r.PatchVersion()-1)
	gpN := fmt.Sprintf("%%global go_patch %d", r.PatchVersion())

	return strings.Replace(*fc, gpO, gpN, 1)
}

func addPatchGoSpec(fc *string, r Release, patch string) string {
	return ""
}

func updateGoSpec(gClient git.Client, r *Release) error {
	// update golang.spec
	goSpecPath := fmt.Sprintf(specPathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), goSpecFile)
	goSpecContent, err := gClient.ReadFile(goSpecPath)
	if err != nil {
		logger.Error(err, "Reading spec.golang", "file", goSpecPath)
		return err
	}
	goSpecContent = updateGoSpecPatchVersion(&goSpecContent, *r)
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

func createReleasePR(ctx context.Context, r *Release, ghUser github.GitHubUser, gClient git.Client) error {
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
		CommitBranch:  r.EksGoReleaseVersion(),
		BaseBranch:    "main",
		AuthorName:    ghUser.User(),
		AuthorEmail:   ghUser.Email(),
		PrSubject:     fmt.Sprintf(updatePRSubjectFmt, r.GoSemver()),
		PrBranch:      "main",
		PrDescription: fmt.Sprintf(updatePRDescriptionFmt, r.EksGoReleaseVersion()),
	}

	commitMsg := fmt.Sprintf(newMinorVersionCommitMsgFmt, r.GoMinorVersion())
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
