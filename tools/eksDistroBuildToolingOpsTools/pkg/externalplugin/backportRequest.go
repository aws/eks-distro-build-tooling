package externalplugin

import (
	"fmt"
	"regexp"
	"sync"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/github"
)

type backportRequest struct {
	project string
	org     string
	repo    string
	issNum  int
}

// Follows the format `/backport:golang 1.2.2 ...
var backportRe = regexp.MustCompile(`(?m)^(?:/backport:)([a-zA-z]+)\s+(.+)$`)

func (s *Server) handleBackportRequest(l *logrus.Entry, requestor string, comment *github.IssueComment, issue *github.Issue, project string, versions []string, org, repo string, num int) error {
	var lock *sync.Mutex
	func() {
		s.mapLock.Lock()
		defer s.mapLock.Unlock()
		if _, ok := s.lockBackportMap[backportRequest{project, org, repo, num}]; !ok {
			if s.lockBackportMap == nil {
				s.lockBackportMap = map[backportRequest]*sync.Mutex{}
			}
			s.lockBackportMap[backportRequest{project, org, repo, num}] = &sync.Mutex{}
		}
		lock = s.lockBackportMap[backportRequest{project, org, repo, num}]
	}()
	lock.Lock()
	defer lock.Unlock()

	//Only a org member should be able to request a issue backport
	if !s.AllowAll {
		ok, err := s.Ghc.IsMember(org, requestor)
		if err != nil {
			return err
		}
		if !ok {
			resp := fmt.Sprintf(constants.AllowAllFailRespTemplate, requestor, org, org)
			l.Info(resp)
			return s.Ghc.CreateComment(org, repo, num, resp)
		}
	}

	// Handle "/backport:<project> [versions] - ie /backport:golang 1.18.12 ...
	switch project {
	case "golang":
	case "go":
		if err := s.backportGolang(l, requestor, comment, issue, project, versions, org, repo, num); err != nil {
			return err
		}
	default:
		if err := s.createComment(l, org, repo, issue.Number, comment, fmt.Sprintf("%s not a valid project for /backport: command", project)); err != nil {
			return err
		}
	}

	return nil
}

func CreateBackportBody(org, repo string, num int, requestor, note string) string {
	backportBody := fmt.Sprintf("This is an automated backport of %s/%s#%d", org, repo, num)
	if len(requestor) != 0 {
		backportBody = fmt.Sprintf("%s\n\n This backport was requested by: %s\n/assign %s", backportBody, requestor, requestor)
	}
	if len(note) != 0 {
		backportBody = fmt.Sprintf("%s\n\nNotes from backported issue:%s", backportBody, note)
	}
	return backportBody
}
