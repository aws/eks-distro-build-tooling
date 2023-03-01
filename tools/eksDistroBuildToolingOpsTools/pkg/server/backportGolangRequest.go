package server

import (
	"fmt"
	"regexp"
	"strconv"
	"sync"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
)

func (s *Server) backportGolang(logger *logrus.Entry, requestor string, comment github.IssueComment, issue github.Issue, project, version, org, repo string, num int) error {
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

	return nil
}

func CreateGolangBackportBody(num int, requestor, note string) string {
	golangBackportBody := fmt.Sprintf("This is an automated backport of %s/%s#%d", constants.GolangOrgName, constants.GoRepoName, num)
	if len(requestor) != 0 {
		golangBackportBody = fmt.Sprintf("%s\n\n/assign %s", golangBackportBody, requestor)
	}
	if len(note) != 0 {
		golangBackportBody = fmt.Sprintf("%s\n\n/assign %s", golangBackportBody, note)
	}
	return golangBackportBody
}

func (s *Server) getGolangIssueFromBody(body string) (github.Issue, error) {
	var issNumRe = regexp.MustCompile(fmt.Sprintf(`(%s)`, constants.GithubIssueRegex))
	goIssueNum := issNumRe.FindString(body)

	i, err := strconv.Atoi(goIssueNum[1:])
	if err != nil {
		return nil, err
	}

	return s.Ghc.GetIssue(constants.GolangOrgName, constants.GoRepoName, i)
}
