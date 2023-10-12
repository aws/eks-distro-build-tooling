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
	updatePRDescriptionFmt = "Update EKS Go Patch Version: %s\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Bump tracking patch version to 1.20.8 from 1.20.7\n```"
	updatePRSubjectFmt     = "New patch release of Golang: %s"
)

// UpdatePatchVersion is for updating the files in https://github.com/aws/eks-distro-build-tooling/golang/go for golang versions still maintained by upstream.
// For EKS Go versions that aren't maintained by upstream, the function is
func UpdateVersion(ctx context.Context, r *Release, dryrun bool, email, user string) error {
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
		logger.Error(err, "Cloning repo", "user", user)
		return err
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

	// Create new branch
	if err := gClient.Branch(r.EksGoReleaseVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Update files for new patch versions of golang
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

	// Commit files
	// set up PR Creator handler
	prmOpts := &prManager.Opts{
		SourceOwner: user,
		SourceRepo:  constants.EksdBuildToolingRepoName,
		PrRepo:      constants.EksdBuildToolingRepoName,
		PrRepoOwner: constants.AwsOrgName,
	}
	prm := prManager.New(retrier, githubClient, prmOpts)

	prOpts := &prManager.CreatePrOpts{
		CommitBranch:  r.EksGoReleaseVersion(),
		BaseBranch:    "main",
		AuthorName:    user,
		AuthorEmail:   email,
		PrSubject:     fmt.Sprintf(updatePRSubjectFmt, r.GoSemver()),
		PrBranch:      "main",
		PrDescription: fmt.Sprintf(updatePRDescriptionFmt, r.EksGoReleaseVersion()),
	}

	if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
		logger.Error(err, "Create Release PR")
	}

	return nil
}
