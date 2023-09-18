package eksGoRelease

import (
  "context"
  "fmt"
  "strconv"
  "time"

  "github.com/go-git/go-git/v5/plumbing/transport/http"
  "go.uber.org/multierr"

  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/executables"
  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
  "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

const (
  backportPRDescriptionFmt = "This PR attempted to patch %s EKS Go Patch Version: %s\n%s\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Patch CVE in EKS Go version 1.20.8\n```"
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

  readmeContent := GenerateReadme(readmeFmt, r)
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
  // Get previous patches from gclient
  patches, err := gClient.ReadFiles(fmt.Sprintf(patchesPathFmt, constants.EksGoProjectPath, r.GoMinorReleaseVersion(), "00"))
  if err != nil {
    logger.Error(err, "get patches from repo")
    return fmt.Errorf("get patches from repo: %v", err)
  }
  fmt.Println(len(patches))
  // Attempt patch generation if it fails, skip updating gospec with new patch number
  // Clone https://github.com/golang/go
  goRepo := git.NewClient(git.WithInMemoryFilesystem(), git.WithRepositoryUrl(constants.GoRepoUrl), git.WithAuth(&http.BasicAuth{Username: user, Password: token}))
  if err := goRepo.Clone(ctx); err != nil {
    logger.Error(err, "Cloning repo")
  }

  if err := goRepo.Branch(r.GoReleaseBranch()); err != nil {
    logger.Error(err, "git branch", "branch name", r.GoReleaseBranch(), "repo", constants.GoRepoUrl, "client", goRepo)
  }
  
  if err != nil {
    logger.Error(err, "Generate Patch failed, continuing with PR")
    patchFailed := fmt.Sprintf("Failed to generate the Patch for %s, due to: %v\nThe patch will need to be generated manually\n", cve, err)
    // Commit files updated to this point. Patch generation can be done manually if the patch
    // fails. The PR description will be updated to reflect the failed patch generation
    if (!dryrun) {
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

      // set up PR Creator handler from fork to aws org
      prmOpts := &prManager.Opts{
        SourceOwner: user,
        SourceRepo:  constants.EksdBuildToolingRepoName,
        PrRepo:      constants.EksdBuildToolingRepoName,
        PrRepoOwner: constants.AwsOrgName,
      }
      prm := prManager.New(retrier, githubClient, prmOpts)

      cprOpts := &prManager.CreatePrOpts{
        CommitBranch:  r.EksGoReleaseFullVersion(),
        BaseBranch:    "main",
        AuthorName:    user,
        AuthorEmail:   email,
        PrSubject:     fmt.Sprintf(backportPRSubjectFmt, cve, r.GoSemver()),
        PrBranch:      "main",
        PrDescription: fmt.Sprintf(backportPRDescriptionFmt, cve, patchFailed, r.EksGoReleaseFullVersion()),
      }

      prUrl, err := prm.CreatePr(ctx, cprOpts)
      if err != nil {
        // This shouldn't be an breaking error at this point the PR is not open but the changes
        // have been pushed and can be created manually.
        logger.Error(err, "github client create pr failed. Create PR manually from github webclient", "create pr opts", cprOpts)
        prUrl = ""
      }

      logger.V(3).Info("Update EKS Go Version", "EKS Go Version", r.EksGoReleaseFullVersion(), "PR", prUrl)
    }
    return nil
  }

  patch := ""
  goSpecContent = addPatchGoSpec(&goSpecContent, r, patch)
  logger.V(4).Info("Update golang.spec", "path", goSpecPath, "content", goSpecContent)
  if err := gClient.ModifyFile(goSpecPath, []byte(goSpecContent)); err != nil {
    return err
  }
  if err := gClient.Add(goSpecPath); err != nil {
    logger.Error(err, "git add", "file", goSpecPath)
    return err
  }

  // Commit files
  if (!dryrun) {
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

    // Add files paths for new Go Minor Version
    // set up PR Creator handler
    prmOpts := &prManager.Opts{
      SourceOwner: user,
      SourceRepo:  constants.EksdBuildToolingRepoName,
      PrRepo:      constants.EksdBuildToolingRepoName,
      PrRepoOwner: user,
    }
    prm := prManager.New(retrier, githubClient, prmOpts)

    cprOpts := &prManager.CreatePrOpts{
      CommitBranch:  r.EksGoReleaseFullVersion(),
      BaseBranch:    "main",
      AuthorName:    user,
      AuthorEmail:   email,
      PrSubject:     fmt.Sprintf(backportPRSubjectFmt, cve, r.GoSemver()),
      PrBranch:      "main",
      PrDescription: fmt.Sprintf(backportPRDescriptionFmt, cve, "", r.EksGoReleaseFullVersion()),
    }

    prUrl, err := prm.CreatePr(ctx, cprOpts)
    if err != nil {
      // This shouldn't be an breaking error at this point the PR is not open but the changes
      // have been pushed and can be created manually.
      logger.Error(err, "github client create pr failed. Create PR manually from github webclient", "create pr opts", cprOpts)
      prUrl = ""
    }

    logger.V(3).Info("Update EKS Go Version", "EKS Go Version", r.EksGoReleaseFullVersion(), "PR", prUrl)
  }

	return nil
}
