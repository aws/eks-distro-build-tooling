package externalplugin

import (
	"fmt"
	"regexp"
	"strconv"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
	utilerrors "k8s.io/apimachinery/pkg/util/errors"
	"k8s.io/test-infra/prow/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
)

// This automation assumes the /backport:golang <version> ... is being commented on a mirrored CVE issue.
// It first creates an issue that adds the version to the CVE issue title like "[version]CVE Issue Title"
// Then attemps to create a patch from the upstream fix, creating a pr on success or commenting on the issue of the failure.
func (s *Server) backportGolang(logger *logrus.Entry, requestor string, comment *github.IssueComment, issue *github.Issue, project string, versions []string, org, repo string, num int) error {
	var lock *sync.Mutex
	func() {
		s.mapLock.Lock()
		defer s.mapLock.Unlock()
		if _, ok := s.lockBackportMap[backportRequest{org, project, repo, num}]; !ok {
			if s.lockBackportMap == nil {
				s.lockBackportMap = map[backportRequest]*sync.Mutex{}
			}
			s.lockBackportMap[backportRequest{org, project, repo, num}] = &sync.Mutex{}
		}
		lock = s.lockBackportMap[backportRequest{org, project, repo, num}]
	}()
	lock.Lock()
	defer lock.Unlock()

	// Only consider non-PR issues for /backport:<project> [versions] requests,
	if issue.IsPullRequest() {
		return nil
	}

	for _, version := range versions {
		// Create an issue that is adds a [version] to the beginning of the issue.
		bpi, err := s.createIssue(logger, org, repo, fmt.Sprintf("[%s]%s", version, issue.Title), CreateBackportBody(constants.GolangOrgName, constants.GoRepoName, issue.Number, requestor, ""), issue.Number, comment, nil, []string{requestor})
		if err != nil {
			return err
		}

		// Get the upstream commit from the events in the base issue. This will need to be monitored as this seems to be the largest area of potential failure.
		// As of Aug 1, 2023 golang uses gopherbot to comment the closing commit hash. This will needed to be updated if they changes this pattern.
		var goMirrorIssueRe = regexp.MustCompile(`(?m)^(?:Mirred Issue:)+(.+)$`)
		var issNumRe = regexp.MustCompile(`(#\d+)`)
		// Expecting only one issue listed in the body following the 'Mirrored Issue:<org>/<repo>#<issue>' format
		issueIncludingRepo := goMirrorIssueRe.FindString(issue.Body)
		mirrorIssueNumber := issNumRe.FindString(issueIncludingRepo)
		iInt, err := strconv.Atoi(mirrorIssueNumber[1:])
		if err != nil {
			return fmt.Errorf("Converting issue number to int: %w", err)
		}
		golangIssueComments, err := s.Ghc.ListIssueComments(constants.GolangOrgName, constants.GoRepoName, iInt)

		// With the golangIssueComments[] find the one tagged as closing with hash. It looks for a comment of the format:
		// "Closed by merging [hash] to ..." collecting only the hash
		// FindStringSubmatch returns a slice of strings holding the text of the leftmost match of the regular expression in s and the matches,
		// if any, of its subexpressions, as defined by the 'Submatch' description in the package comment. A return value of nil indicates no match.
		// So we want the value at match[1], since that will have the submatch or the [commithash]
		var gopherbotCommentRe = regexp.MustCompile(`(?m)^(?:Closed by merging)\s(.+)\s(?:to)(?:.+)$`)
		var commitHash string
		for _, ghComment := range golangIssueComments {
			match := gopherbotCommentRe.FindStringSubmatch(ghComment.Body)
			if len(match) > 1 {
				commitHash = match[1]
				break //break here we found the commit hash
			}
			logger.WithError(err).Warn("failed to get commit hash")
			resp := fmt.Sprintf("cannot find hash for issue: %v", err)
			return s.createComment(logger, org, repo, num, comment, resp)
		}

		//Begin attempting to backport the upstream fix to EKS Golang <Version>
		goFork, err := s.ensureForkExists(constants.GolangOrgName, constants.GoRepoName)
		if err != nil {
			logger.WithError(err).Warn("failed to ensure fork exists")
			resp := fmt.Sprintf("cannot fork %s/%s: %v", constants.GolangOrgName, constants.GoRepoName, err)
			return s.createComment(logger, org, repo, num, comment, resp)
		}

		eksdbFork, err := s.ensureForkExists(constants.GolangOrgName, constants.GoRepoName)
		if err != nil {
			logger.WithError(err).Warn("failed to ensure fork exists")
			resp := fmt.Sprintf("cannot fork %s/%s: %v", constants.AwsOrgName, constants.EksdBuildToolingRepoName, err)
			return s.createComment(logger, org, repo, num, comment, resp)
		}

		// Clone EKS-Distro-Build-Tooling, checkout the branch to attempt the PR
		startClone := time.Now()
		eksdbBranch := fmt.Sprintf(constants.ProjectBotBranchFmt, constants.GolangOrgName, bpi)
		eksdb, err := s.Gc.ClientFor(constants.AwsOrgName, constants.EksdBuildToolingRepoName)
		if err != nil {
			return fmt.Errorf("failed to get git client for %s/%s: %v", constants.AwsOrgName, eksdbFork, err)
		}
		defer func() {
			if err := eksdb.Clean(); err != nil {
				logger.WithError(err).Error("Error cleanign up repo.")
			}
		}()
		if eksdb.BranchExists(eksdbBranch) {
			// Find the PR and link to it.
			prs, err := s.Ghc.GetPullRequests(org, repo)
			if err != nil {
				return fmt.Errorf("failed to get pullrequests for %s/%s: %w", org, repo, err)
			}
			for _, pr := range prs {
				if pr.Head.Ref == fmt.Sprintf("%s:%s", s.BotUser.Login, eksdbBranch) {
					logger.WithField("preexisting_golang_backport", pr.HTMLURL).Info("Issue already has a backport attempt")
					resp := fmt.Sprintf("Looks like #%d has already been backported in %s", num, pr.HTMLURL)
					return s.createComment(logger, org, repo, num, comment, resp)
				}
			}
		}

		if err := eksdb.CheckoutNewBranch(eksdbBranch); err != nil {
			logger.WithError(err).Warn("failed to checkout eksdb branch")
			resp := fmt.Sprintf("cannot checkout `%s`: %v", eksdbBranch, err)
			return s.createComment(logger, org, repo, num, comment, resp)
		}
		logger.WithField("duration", time.Since(startClone)).Info("Cloned and checked out new branch.")

		// Clone golang/go, checkout the version tag to attempt a cherrypick
		// of the desired hash after adding the existing patches
		startClone = time.Now()
		//Golang release branches follow the format: release-branch.go1.18 the version slice [0:4] gives the first 4 values of the semver. ex 1.18
		goBranch := fmt.Sprintf(constants.GoReleaseBranchFmt, version[0:4])
		goGc, err := s.Gc.ClientFor(constants.GolangOrgName, constants.GolangOrgName)
		if err != nil {
			return fmt.Errorf("failed to get git client for %s/%s: %v", constants.GolangOrgName, goFork, err)
		}
		defer func() {
			if err := eksdb.Clean(); err != nil {
				logger.WithError(err).Error("Error cleanign up repo.")
			}
		}()
		// Git fetch to gather release tags
		if err := goGc.Fetch(); err != nil {
			logger.WithError(err).Warn("failed to run git fetch")
			resp := fmt.Sprintf("cannot git fetch: %v", err)
			return s.createComment(logger, org, repo, num, comment, resp)
		}

		if err := goGc.Checkout(goBranch); err != nil {
			logger.WithError(err).Warn("failed to checkout go release branch")
			resp := fmt.Sprintf("cannot checkout `%s`: %v", goBranch, err)
			return s.createComment(logger, org, repo, num, comment, resp)
		}
		logger.WithField("duration", time.Since(startClone)).Info("Cloned and checked out release branch.")

		// Git am the previous patches in for the version
		patchesDir := fmt.Sprintf(constants.EksGoPatchPathFmt, eksdb.Directory(), version[0:4])
		if err := goGc.Am(patchesDir); err != nil {
			errs := []error{fmt.Errorf("failed to `git am`: %w", err)}
			logger.WithError(err).Warn("failed to apply existing patchs on top of target release branch")
			resp := fmt.Sprintf("#%d failed to apply existing patches on top of release branch %q:\n```\n%v\n```", num, goBranch, err)
			if err := s.createComment(logger, org, repo, num, comment, resp); err != nil {
				errs = append(errs, fmt.Errorf("failed to create comment: %w", err))
			}

			if s.IssueOnConflict {
				resp = fmt.Sprintf("Manual backport required.\n\n%v", resp)
				if err := s.createComment(logger, org, repo, bpi, comment, resp); err != nil {
					errs = append(errs, fmt.Errorf("failed to create comment: %w", err))
				}
			}

			return utilerrors.NewAggregate(errs)
		}

		if err := localCherryPick(commitHash); err != nil {
			errs := []error{fmt.Errorf("failed to `git cherry-pick %s`: %w", commitHash, err)}
			logger.WithError(err).Warn("failed to apply backport patch on top of target release branch")
			resp := fmt.Sprintf("#%d failed to apply backport patch on top of release branch %q:\n```\n%v\n```", num, goBranch, err)
			if err := s.createComment(logger, org, repo, num, comment, resp); err != nil {
				errs = append(errs, fmt.Errorf("failed to create comment: %w", err))
			}

			if s.IssueOnConflict {
				resp = fmt.Sprintf("Manual backport required.\n\n%v", resp)
				if err := s.createComment(logger, org, repo, bpi, comment, resp); err != nil {
					errs = append(errs, fmt.Errorf("failed to create comment: %w", err))
				}
			}

			return utilerrors.NewAggregate(errs)
		}

		if err := localFormatPatch(); err != nil {
			errs := []error{fmt.Errorf("failed to `git format-patch: %w", err)}
			logger.WithError(err).Warn("failed to format patch")
			resp := fmt.Sprintf("#%d failed to format patch:\n```\n%v\n```", num, err)
			if err := s.createComment(logger, org, repo, num, comment, resp); err != nil {
				errs = append(errs, fmt.Errorf("failed to create comment: %w", err))
			}

			if s.IssueOnConflict {
				resp = fmt.Sprintf("Manual backport required.\n\n%v", resp)
				if err := s.createComment(logger, org, repo, bpi, comment, resp); err != nil {
					errs = append(errs, fmt.Errorf("failed to create comment: %w", err))
				}
			}

			return utilerrors.NewAggregate(errs)
		}

		//TODO: Copy formatted patch to
		// patchesDir

		push := eksdb.PushToNamedFork
		if s.Push != nil {
			push = s.Push
		}
		// Push the new branch in the bot's fork.
		if err := push(eksdbFork, eksdbBranch, true); err != nil {
			logger.WithError(err).Warn("failed to push changes to GitHub")
			resp := fmt.Sprintf("failed to push changes in GitHub: %v", err)
			return utilerrors.NewAggregate([]error{err, s.createComment(logger, org, repo, num, comment, resp)})
		}

		// Open a PR in GitHub.
		title := fmt.Sprintf("[%s]%s - EKSGo", version, issue.Title)
		var backportPrBody string
		backportPrBody = createBackportPrBody(bpi, requestor)

		head := fmt.Sprintf("%s:%s", s.BotUser.Login, eksdbBranch)
		createdNum, err := s.Ghc.CreatePullRequest(constants.AwsOrgName, constants.EksdBuildToolingRepoName, title, backportPrBody, head, eksdbBranch, true)
		if err != nil {
			logger.WithError(err).Warn("failed to create new pull request")
			resp := fmt.Sprintf("new pull request could not be created: %v", err)
			return utilerrors.NewAggregate([]error{err, s.createComment(logger, org, repo, num, comment, resp)})
		}
		*logger = *logger.WithField("new_pull_request_number", createdNum)
		resp := fmt.Sprintf("new pull request created: #%d", createdNum)
		logger.Info("new pull request created")
		if err := s.createComment(logger, org, repo, num, comment, resp); err != nil {
			return fmt.Errorf("failed to create comment: %w", err)
		}
	}

	return nil
}

func createBackportPrBody(num int, requestor string) string {
	backportPrBody := fmt.Sprintf("This is an automated backport of #%d", num)
	if len(requestor) != 0 {
		backportPrBody = fmt.Sprintf("%s\n\n/assign %s", backportPrBody, requestor)
	}
	return backportPrBody
}

// TODO: Write functions to locally execute `git cherry-pick commit`
func localCherryPick(commit string) error {
	return nil
}

// TODO: Write functions to locally execute `git format-patch -1`
func localFormatPatch() error {
	return nil
}
