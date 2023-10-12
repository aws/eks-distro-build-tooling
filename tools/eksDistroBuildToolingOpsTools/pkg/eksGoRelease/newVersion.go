package eksGoRelease

const (
	newMinorVersionCommitMsgFmt     = "Init new Go Minor Version %s files."
	newMinorVersionPRSubjectFmt     = "New minor release of Golang: %s"
	newMinorVersionPRDescriptionFmt = "Update EKS Go Patch Version: %s\nSPEC FILE STILL NEEDS THE '%%changelog' UPDATED\nPLEASE UPDATE WITH THE FOLLOWING FORMAT\n```\n* Wed Sep 06 2023 Cameron Rozean <rcrozean@amazon.com> - 1.20.8-1\n- Bump tracking patch version to 1.20.8 from 1.20.7\n```"
)

// Releasing new versions of Golang that don't exist in EKS Distro Build Tooling(https://github.com/aws/eks-distro-build-tooling/projects/golang/go)
func NewMinorRelease(ctx context.Context, r *Release, dryrun bool, email, user string) error {
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
	// Create new branch
	if err := gClient.Branch(r.EksGoReleaseVersion()); err != nil {
		logger.Error(err, "git branch", "branch name", r.EksGoReleaseVersion(), "repo", forkUrl, "client", gClient)
		return err
	}

	// Add files for new minor versions of golang.
	// Add README.md
	readmePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.Readme)
	readmeFmt, err := gClient.ReadFile(readmeFmtPath)
	if err != nil {
		logger.Error(err, "Reading README fmt file")
		return err
	}

	readmeContent := generateReadme(readmeFmt, r)

	logger.V(4).Info("Create README.md", "path", readmePath, "content", readmeContent)
	if err := gClient.CreateFile(readmePath, []byte(readmeContent)); err != nil {
		logger.Error(err, "Adding README.md", "path", readmePath, "content", readmeContent)
		return err
	}
	if err := gClient.Add(readmePath); err != nil {
		logger.Error(err, "git add", "file", readmePath)
		return err
	}

	// Add RELEASE
	releasePath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.ReleaseTag)
	releaseContent := fmt.Sprintf("%d", r.ReleaseNumber())
	if err := gClient.CreateFile(releasePath, []byte(releaseContent)); err != nil {
		logger.Error(err, "Adding RELEASE", "path", releasePath, "content", releaseContent)
		return err
	}
	if err := gClient.Add(releasePath); err != nil {
		logger.Error(err, "git add", "file", releasePath)
		return err
	}

	// Add GIT_TAG
	gittagPath := fmt.Sprintf(basePathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), constants.GitTag)
	gittagContent := fmt.Sprintf("go%s", r.GoFullVersion())
	if err := gClient.CreateFile(gittagPath, []byte(gittagContent)); err != nil {
		logger.Error(err, "Adding GIT_TAG", "path", gittagPath, "content", gittagContent)
		return err
	}
	if err := gClient.Add(gittagPath); err != nil {
		logger.Error(err, "git add", "file", gittagPath)
		return err
	}

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

	// Add temp file in <version>/patches/
	patchesFilePath := fmt.Sprintf(patchesPathFmt, constants.EksGoProjectPath, r.GoMinorVersion(), "temp")
	patchesContent := []byte("Copy")
	if err := gClient.CreateFile(patchesFilePath, patchesContent); err != nil {
		logger.Error(err, "Adding patches folder path", "path", patchesFilePath)
		return err
	}
	if err := gClient.Add(patchesFilePath); err != nil {
		logger.Error(err, "git add", "file", patchesFilePath)
		return err
	}

	// Commit files
	// Add files paths for new Go Minor Version
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
		PrSubject:     fmt.Sprintf("Add path for new release of Golang: %s", r.GoSemver()),
		PrBranch:      "main",
		PrDescription: fmt.Sprintf("Init Go Minor Version: %s", r.GoMinorVersion()),
	}

	if err := createReleasePR(ctx, r, gClient, dryrun, prm, prOpts); err != nil {
		logger.Error(err, "Create Release PR")
	}

	return nil
}
