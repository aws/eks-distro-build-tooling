package eksGoRelease

import (
	"context"
	"fmt"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/go-git/go-git/v5/plumbing/transport/http"
)

const (
	releasePRCommitFmt      = "Release EKS Go version %s"
	releasePRDescriptionFmt = "Increment release file to publish new EKS Go artifacts for %s"
	releasePRSubjectFmt     = "Release EKS Go: %s"
)

// UpdatePatchVersion is for updating the files in https://github.com/aws/eks-distro-build-tooling/golang/go for golang versions still maintained by upstream.
// For EKS Go versions that aren't maintained by upstream, the function is
func ReleaseArtifacts(ctx context.Context, r *Release, dryrun bool, email, user string) error {
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

	// Increment Release
	if err := bumpRelease(gClient, r); err != nil {
		logger.Error(err, "increment release")
		return err
	}

	// Create new branch
	if err := gClient.Branch(fmt.Sprintf("release-%s", r.GoMinorVersion())); err != nil {
		logger.Error(err, "git branch", "branch name", r.GoMinorVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Increment release files
	if err := updateRelease(gClient, r); err != nil {
		logger.Error(err, "updating release file", "release", r.EksGoReleaseVersion())
		return err
	}

	// Commit files and create PR
	prSubject := fmt.Sprintf(releasePRSubjectFmt, r.EksGoReleaseVersion())
	prDescription := fmt.Sprintf(releasePRDescriptionFmt, r.EksGoReleaseVersion())
	commitMsg := fmt.Sprintf(releasePRCommitFmt, r.EksGoReleaseVersion())
	if err := createReleasePR(ctx, dryrun, r, ghUser, gClient, prSubject, prDescription, commitMsg); err != nil {
		logger.Error(err, "Create Release PR")
	}
	return nil
}
