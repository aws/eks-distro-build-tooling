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
	updatePRDescriptionFmt = "Update EKS Go Patch Version: %s\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Bump tracking patch version to 1.20.8 from 1.20.7\n```"
	updatePRSubjectFmt     = "New patch release of Golang: %s"
)

// UpdatePatchVersion is for updating the files in https://github.com/aws/eks-distro-build-tooling/golang/go for golang versions still maintained by upstream.
// For EKS Go versions that aren't maintained by upstream, the function is
func UpdateVersion(ctx context.Context, r *Release, dryrun bool, email, user string) error {
	// Setup Git Clients
	token, err := github.GetGithubToken()
	if err != nil {
		logger.V(4).Error(err, "no github token found")
		return fmt.Errorf("getting Github PAT from environment at variable %s: %v", github.PersonalAccessTokenEnvVar, err)
	}

	ghUser := github.NewGitHubUser(user, email, token)
	logger.V(5).Info("github user", "user", ghUser.User(), "email", ghUser.Email(), "token", ghUser.Token())
	// Creating git client in memory and clone 'eks-distro-build-tooling
	forkUrl := fmt.Sprintf(constants.EksGoRepoUrl, ghUser.User())
	gClient := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(forkUrl), git.WithAuth(&http.BasicAuth{Username: ghUser.User(), Password: ghUser.Token()}))
	if err := gClient.Clone(ctx); err != nil {
		logger.Error(err, "Cloning repo", "user", ghUser.User())
		return err
	}

	// Increment Release
	if err := bumpRelease(gClient, r); err != nil {
		logger.Error(err, "increment release")
		return err
	}

	// Create new branch
	if err := gClient.Branch(r.EksGoReleaseVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Update files for new patch versions of golang
	if err := updateReadme(gClient, r); err != nil {
		logger.Error(err, "Update Readme")
		return err
	}

	if err := updateGoSpec(gClient, r); err != nil {
		logger.Error(err, "Update Readme")
		return err
	}

	// Create PR if not dryrun
	if !dryrun {
		if err := createReleasePR(ctx, r, ghUser, gClient); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}
	return nil
}
