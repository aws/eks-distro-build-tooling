package server

import (
	"fmt"
	"regexp"
	"strings"
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

func (s *Server) handleBackportRequest(l *logrus.Entry, requestor string, issue *github.Issue, backportMatches []string, org, repo string, num int) error {
	var lock *sync.Mutex
	func() {
		s.mapLock.Lock()
		defer s.mapLock.Unlock()
		if _, ok := s.lockBackportMap[backportRequest{org, repo, num}]; !ok {
			if s.lockBackportMap == nil {
				s.lockBackportMap = map[backportRequest]*sync.Mutex{}
			}
			s.lockBackportMap[backportRequest{org, repo, num}] = &sync.Mutex{}
		}
		lock = s.lockBackportMap[backportRequest{org, repo, num}]
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
			resp := fmt.Sprintf("only [%s](https://github.com/orgs/%s/people) org members may request may trigger automated issues. You can still create the issue manually.", org, org)
			l.Info(resp)
			return s.Ghc.CreateComment(org, repo, num, resp)
		}
	}

	// Handle "/backport all"

	// Handle "/backport v1.15.15 ...
	for _, version := range backportMatches {
		_, err := s.Ghc.CreateIssue(org, repo, fmt.Sprintf("[%s]%s", version, issue.Title), s.generateBackportIssueBody(issue, requestor), 0, nil, []string{requestor})
		if err != nil {
			return err
		}
	}
	return nil
}

func (s *Server) generateBackportIssueBody(issue *github.Issue, requestor string) string {
	b := strings.Builder{}

	b.WriteString(fmt.Sprintf("A backport of issue %v was requested by @%v\n", issue.HTMLURL, requestor))
	b.WriteString(fmt.Sprintf("%v", issue.Body))
	bs := b.String()
	return bs
}
