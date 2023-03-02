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

type golangPatchReleaseRequest struct {
	org    string
	repo   string
	issNum int
}

// Currently handling Golang Patch Releases and Golang Minor Releases
var golangPatchReleaseRe = regexp.MustCompile(`(?m)^(?:Golang Patch Release:)\s+(.+)$`)

func (s *Server) handleGolangPatchRelease(l *logrus.Entry, requestor string, issue *github.Issue, org, repo, title, body string, num int) error {
	var lock *sync.Mutex
	func() {
		s.mapLock.Lock()
		defer s.mapLock.Unlock()
		if _, ok := s.lockGolangPatchMap[golangPatchReleaseRequest{org, repo, num}]; !ok {
			if s.lockGolangPatchMap == nil {
				s.lockGolangPatchMap = map[golangPatchReleaseRequest]*sync.Mutex{}
			}
			s.lockGolangPatchMap[golangPatchReleaseRequest{org, repo, num}] = &sync.Mutex{}
		}
		lock = s.lockGolangPatchMap[golangPatchReleaseRequest{org, repo, num}]
	}()
	lock.Lock()
	defer lock.Unlock()

	if requestor != constants.EksDistroBotName || !s.AllowAll {
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

	var golangVersionsRe = regexp.MustCompile(`(?m)(\d+.\d+.\d+)`)
	var issNumRe = regexp.MustCompile(`(#\d+)`)
	m := make(map[string]int)
	for _, version := range golangVersionsRe.FindAllString(issue.Title, -1) {
		query := fmt.Sprintf("repo:%s/%s milestone:Go%s label:Security", constants.GolangOrgName, constants.GoRepoName, version)
		milestoneIssues, err := s.Ghc.FindIssuesWithOrg(constants.GolangOrgName, query, "", false)
		if err != nil {
			return fmt.Errorf("Find Golang Milestone: %v", err)
		}
		for _, i := range milestoneIssues {
			for _, biMatch := range issNumRe.FindAllString(i.Body, -1) {
				if m[biMatch] == 0 {
					m[biMatch] = 1
				}
			}
		}
	}
	for biNum := range m {
		biInt, err := strconv.Atoi(biNum[1:])
		if err != nil {
			return fmt.Errorf("Converting issue number to int: %w", err)
		}
		baseIssue, err := s.Ghc.GetIssue(constants.GolangOrgName, constants.GoRepoName, biInt)
		if err != nil {
			return fmt.Errorf("Getting base issue(%s/%s#%d): %w", constants.GolangOrgName, constants.GoRepoName, biInt, err)
		}
		miNum, err := s.Ghc.CreateIssue(constants.AwsOrgName, constants.EksdBuildToolingRepoName, baseIssue.Title, baseIssue.Body, 0, nil, nil)
		if err != nil {
			return fmt.Errorf("Creating mirrored issue: %w", err)
		}
		l.Info(fmt.Sprintf("Created Issue: %s/%s#%d", constants.AwsOrgName, constants.EksdBuildToolingRepoName, miNum))
	}
	return nil
}
