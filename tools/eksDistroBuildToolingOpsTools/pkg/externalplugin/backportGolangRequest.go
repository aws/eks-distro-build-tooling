package externalplugin

import (
	"fmt"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
)

func (s *Server) backportGolang(logger *logrus.Entry, requestor string, comment *github.IssueComment, issue *github.Issue, targetBranch string, project string, versions []string, org, repo string, num int) error {
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
	// For PR requests it seems more fitting to use the /cherrypick command provided by Prow
	if issue.IsPullRequest() {
		return nil
	}

	for _, version := range versions {
		err := s.createIssue(logger, org, repo, fmt.Sprintf("[%s]%s", version, issue.Title), CreateBackportBody(constants.GolangOrgName, constants.GoRepoName, issue.Number, requestor, ""), issue.Number, comment, nil, []string{requestor})
		if err != nil {
			return err
		}
	}

	forkName, err := s.ensureForkExists(org, repo)
	if err != nil {
		logger.WithError(err).Warn("failed to ensure fork exists")
		resp := fmt.Sprintf("cannot fork %s/%s: %v", org, repo, err)
		return s.createComment(logger, org, repo, num, comment, resp)
	}

	// Clone the repo, checkout the target branch.
	startClone := time.Now()
	r, err := s.Gc.ClientFor(org, repo)
	if err != nil {
		return fmt.Errorf("failed to get git client for %s/%s: %w", org, forkName, err)
	}
	defer func() {
		if err := r.Clean(); err != nil {
			logger.WithError(err).Error("Error cleaning up repo.")
		}
	}()
	if err := r.Checkout(targetBranch); err != nil {
		logger.WithError(err).Warn("failed to checkout target branch")
		resp := fmt.Sprintf("cannot checkout `%s`: %v", targetBranch, err)
		return s.createComment(logger, org, repo, num, comment, resp)
	}
	logger.WithField("duration", time.Since(startClone)).Info("Cloned and checked out target branch.")

	return nil
}
