package eksGoRelease

import (
	"context"
	"fmt"
	"strconv"
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
	backportPRDescriptionFmt = "This PR attempted to patch %s EKS Go Patch Version: %s\n\n/hold\n\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Patch CVE in EKS Go version 1.20.8\n```"
	backportPRSubjectFmt     = "Patch %s to EKS Go %s"
)

// BackportPatchVersion is for updating the files in https://github.com/aws/eks-distro-build-tooling/golang/go for golang versions no longer maintained by upstream.
func (r Release) BackportToRelease(ctx context.Context, dryrun bool, cve, commit, email, user string) error {
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

	// Get Current EKS Go Release Version from repo and increment
	releasePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), constants.ReleaseTag)
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

	// Create new branch
	if err := gClient.Branch(r.EksGoReleaseFullVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseFullVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Update files for new patch versions of golang
	// Update README.md
	readmePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), constants.Readme)
	readmeFmt, err := gClient.ReadFile(readmeFmtPath)
	if err != nil {
		logger.Error(err, "Reading README fmt file")
		return err
	}

	readmeContent := generateReadme(readmeFmt, r)
	logger.V(4).Info("Update README.md", "path", readmePath, "content", readmeContent)
	if err := gClient.ModifyFile(readmePath, []byte(readmeContent)); err != nil {
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		return err
	}

	// update RELEASE
	releaseContent := fmt.Sprintf("%d", r.ReleaseNumber())
	logger.V(4).Info("Update RELEASE", "path", releasePath, "content", releaseContent)
	if err := gClient.ModifyFile(releasePath, []byte(releaseContent)); err != nil {
		return err
	}
	if err := gClient.Add(releasePath); err != nil {
		logger.Error(err, "git add", "file", releasePath)
		return err
	}

	// update GIT_TAG
	gittagPath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), constants.GitTag)
	gittagContent := fmt.Sprintf("go%s", r.GoFullVersion())
	logger.V(4).Info("Update GIT_TAG", "path", gittagPath, "content", gittagContent)
	if err := gClient.ModifyFile(gittagPath, []byte(gittagContent)); err != nil {
		return err
	}
	if err := gClient.Add(gittagPath); err != nil {
		logger.Error(err, "git add", "file", gittagPath)
		return err
	}

	// update golang.spec
	goSpecPath := fmt.Sprintf(specPathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), goSpecFile)
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

	/* -----
	 * Begin applying previous patches and attempting to cherry-pick the new commit. Any errors from here on out should result in cutting a pr without a new patch,
	 * but shouldn't fail the automation because the patch can be generated manually
	----- */
	// set up PR Creator handler from fork to aws org
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
		PrSubject:     fmt.Sprintf(backportPRSubjectFmt, cve, r.GoSemver()),
		PrBranch:      "main",
		PrDescription: fmt.Sprintf(backportPRDescriptionFmt, cve, r.EksGoReleaseFullVersion()),
	}

	// Get previous patches from gclient
	patches, err := gClient.ReadFiles(fmt.Sprintf(patchesPathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), "00"))
	if err != nil {
		logger.Error(err, "Get existing patches")
		logger.V(3).Info("Generate Patch failed, continuing with PR")
		if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}
	fmt.Println(len(patches))
	// Attempt patch generation if it fails, skip updating gospec with new patch number
	// Clone https://github.com/golang/go
	goRepo := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(constants.GoRepoUrl), git.WithAuth(&http.BasicAuth{Username: user, Password: token}))
	if err := goRepo.Clone(ctx); err != nil {
		logger.Error(err, "Cloning go repo")
		logger.V(3).Info("Generate Patch failed, continuing with PR")
		if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}

	if err := goRepo.Branch(r.GoReleaseBranch()); err != nil {
		logger.Error(err, "git branch", "branch name", r.GoReleaseBranch(), "repo", constants.GoRepoUrl, "client", goRepo)
		logger.V(3).Info("Generate Patch failed, continuing with PR")
		if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}

	patch := ""
	goSpecContent = addPatchGoSpec(&goSpecContent, r, patch)
	logger.V(4).Info("Update golang.spec", "path", goSpecPath, "content", goSpecContent)
	if err := gClient.ModifyFile(goSpecPath, []byte(goSpecContent)); err != nil {
		logger.Error(err, "modify file", "file", goSpecPath)
		if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}
	if err := gClient.Add(goSpecPath); err != nil {
		logger.Error(err, "git add", "file", goSpecPath)
		if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}

	if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
		logger.Error(err, "Create Release PR")
	}

	return nil
}
