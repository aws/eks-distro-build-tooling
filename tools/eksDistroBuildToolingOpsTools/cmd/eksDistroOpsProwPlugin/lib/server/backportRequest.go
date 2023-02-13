package server

import (
	"fmt"
	"regexp"
	"sync"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/github"
)

type backportRequest struct {
	org    string
	repo   string
	issNum int
}

// Currently handling Golang Patch Releases and Golang Minor Releases
var backportRe = regexp.MustCompile(`(?m)^(?:/backport)\s+(.+)$`)

func (s *Server) handleBackportRequest(logger *logrus.Entry, requestor string, issue *github.Issue, backportMatches []string, org, repo string, num int) error {
	var lock *sync.Mutex
	func() {
		s.mapLock.Lock()
		defer s.mapLock.Unlock()
		if _, ok := s.lockMap[backportRequest{org, repo, num}]; !ok {
			if s.lockMap == nil {
				s.lockMap = map[backportRequest]*sync.Mutex{}
			}
			s.lockMap[backportRequest{org, repo, num}] = &sync.Mutex{}
		}
		lock = s.lockMap[backportRequest{org, repo, num}]
	}()
	lock.Lock()
	defer lock.Unlock()

	//Only a org member should be able to request a issue backport
	if !s.allowAll {
		ok, err := s.ghc.IsMember(org, auth)
		if err != nil {
			return err
		}
		if !ok {
			resp := fmt.Sprintf("only [%s](https://github.com/orgs/%s/people) org members may request may trigger automated issues. You can still create the issue manually.", org, org)
			l.Info(resp)
			return s.ghc.CreateComment(org, repo, num, resp)
		}
	}

	// Handle "/backport all"

	// Handle "/backport v1.15.15 ...

	return nil
}
