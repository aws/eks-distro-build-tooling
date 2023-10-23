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
	backportCommitMsgFmt     = "%s"
	backportPRDescriptionFmt = "This PR attempted to patch %s EKS Go Patch Version: %s\n\n/hold\n\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Patch CVE in EKS Go version 1.20.8\n```"
	backportPRSubjectFmt     = "Patch %s to EKS Go %s"
)

// BackportPatchVersion is for updating the files in https://github.com/aws/eks-distro-build-tooling/golang/go for golang versions no longer maintained by upstream.
func BackportToRelease(ctx context.Context, r *Release, dryrun bool, cve, commit, email, user string) error {
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
	if err := gClient.Branch(r.EksGoReleaseVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Update files for new patch versions of golang
	if err := updateVersionReadme(gClient, r); err != nil {
		logger.Error(err, "Update Readme")
		return err
	}

	if err := updateGitTag(gClient, r); err != nil {
		logger.Error(err, "Update GitTag")
		return err
	}

	bi := BackportInfo{
		createPatch: true,
		commitHash:  commit,
	}
	if err := updateGoSpec(gClient, r, bi); err != nil {
		logger.Error(err, "Update Readme")
		return err
	}
	// TODO: Clean this up
	/* -----
	 * Begin applying previous patches and attempting to cherry-pick the new commit. Any errors from here on out should result in cutting a pr without a new patch,
	 * but shouldn't fail the automation because the patch can be generated manually
	----- */
	// TODO: correct the prSubject, prDescription, commitMsg
	prSubject := fmt.Sprintf(backportPRSubjectFmt, r.EksGoReleaseVersion(), "")
	prDescription := fmt.Sprintf(backportPRDescriptionFmt, r.EksGoReleaseVersion(), "")
	commitMsg := ""
	// Get previous patches from gclient
	// Commit files and create PR if not dryrun
	goRepo := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(constants.GoRepoUrl), git.WithAuth(&http.BasicAuth{Username: user, Password: token}))
	if err := goRepo.Clone(ctx); err != nil {
		logger.Error(err, "Cloning go repo")
		logger.V(3).Info("Generate Patch failed, continuing with PR")
		if err := createReleasePR(ctx, dryrun, r, ghUser, gClient, prSubject, prDescription, commitMsg); err != nil {
			logger.Error(err, "Create Release PR")
			return err
		}
	}
	// Checkout upstream version to apply patches too
	if err := bi.golangClient.Branch(r.GoReleaseBranch()); err != nil {
		logger.Error(err, "git branch", "branch name", r.GoReleaseBranch(), "repo", constants.GoRepoUrl, "client", bi.golangClient)
		logger.V(3).Info("Generate Patch failed, continuing with PR")
		if !dryrun {
			if err := createReleasePR(ctx, dryrun, r, ghUser, gClient, prSubject, prDescription, commitMsg); err != nil {
				logger.Error(err, "Create Release PR")
				return err
			}
		}
	}

	if !dryrun {
		prSubject := fmt.Sprintf(updatePRSubjectFmt, r.GoSemver())
		prDescription := fmt.Sprintf(updatePRDescriptionFmt, r.EksGoReleaseVersion())
		commitMsg := fmt.Sprintf(updatePRCommitFmt, r.GoSemver())
		if err := createReleasePR(ctx, dryrun, r, ghUser, gClient, prSubject, prDescription, commitMsg); err != nil {
			logger.Error(err, "Create Release PR")
		}
	}
	return nil
}
