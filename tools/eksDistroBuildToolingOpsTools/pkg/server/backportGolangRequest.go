package server

import (
	"fmt"
	"sync"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
)

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

	return nil
}
