package eksGoRelease

import (
	"context"
	"fmt"

	"github.com/go-git/go-git/v5/plumbing/transport/http"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

const (
	newMinorVersionCommitMsgFmt     = "Init new Go Minor Version %s files."
	newMinorVersionPRSubjectFmt     = "New minor release of Golang: %s"
	newMinorVersionPRDescriptionFmt = "Update EKS Go Patch Version: %s\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Bump tracking patch version to 1.20.8 from 1.20.7\n```"
)

// Releasing new versions of Golang that don't exist in EKS Distro Build Tooling(https://github.com/aws/eks-distro-build-tooling/projects/golang/go)
func NewMinorRelease(ctx context.Context, r *Release, dryrun bool, email, user string) error {
	// Setup Git Clients
	token, err := github.GetGithubToken()
	if err != nil {
		logger.V(4).Error(err, "no github token found")
		return fmt.Errorf("getting Github PAT from environment at variable %s: %v", github.PersonalAccessTokenEnvVar, err)
	}

	ghUser := github.NewGitHubUser(user, email, token)
	// Creating git client in memory and clone 'eks-distro-build-tooling
	forkUrl := fmt.Sprintf(constants.EksGoRepoUrl, ghUser.User())
	gClient := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(forkUrl), git.WithAuth(&http.BasicAuth{Username: ghUser.User(), Password: ghUser.Token()}))
	if err := gClient.Clone(ctx); err != nil {
		logger.Error(err, "Cloning repo", "user", ghUser.User())
		return err
	}

	// Create new branch
	commitBranch := r.EksGoReleaseVersion()
	if err := gClient.Branch(commitBranch); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	if err := updateProjectReadme(gClient, r); err != nil {
		logger.Error(err, "update project Readme")
		return err
	}

	// Create files for new minor versions of golang
	if err := updateVersionReadme(gClient, r); err != nil {
		logger.Error(err, "update version Readme")
		return err
	}

	if err := updateGitTag(gClient, r); err != nil {
		logger.Error(err, "update Readme")
		return err
	}

	if err := addTempFilesForNewMinorVersion(gClient, r); err != nil {
		logger.Error(err, "creating temporary files for new minor verions")
		return err
	}

	// Commit file and create PR if not dryrun
	prSubject := fmt.Sprintf(newMinorVersionPRSubjectFmt, r.GoSemver())
	prDescription := fmt.Sprintf(newMinorVersionPRDescriptionFmt, r.EksGoReleaseVersion())
	commitMsg := fmt.Sprintf(newMinorVersionCommitMsgFmt, r.GoSemver())
	if err := createReleasePR(ctx, dryrun, r, ghUser, gClient, prSubject, prDescription, commitMsg, commitBranch); err != nil {
		logger.Error(err, "Create Release PR")
	}
	return nil
}
