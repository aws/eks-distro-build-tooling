package externalplugin

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

	// This check to see if the requestor is an AWS org member. We restrict the ability to trigger the automation.
	// to AWS org memebers or the EksDistroPrBot
	ok, err := s.Ghc.IsMember(org, requestor)
	if !ok && requestor != constants.EksDistroPrBotName {
		resp := fmt.Sprintf(constants.AllowAllFailRespTemplate, requestor, org, org)
		l.Info(resp)
		return s.Ghc.CreateComment(org, repo, num, resp)
	}
	if err != nil {
		return err
	}

	semvarRegex := fmt.Sprintf(`(?m)(%s)`, constants.SemverRegex)
	var golangVersionsRe = regexp.MustCompile(semvarRegex)
	var issNumRe = regexp.MustCompile(`(#\d+)`)
	m := make(map[string]int)
	// Using regex remove the versions of golang listed in the release announcement. Then generate a query to look through their milestones
	// for closed issues attached to the corresponding milestones tagged "Security". In these issues there is a base issue tagged, we want this issue
	// and create a map to ensure we don't create duplicate issues.
	for _, version := range golangVersionsRe.FindAllString(issue.Title, -1) {
		query := fmt.Sprintf("repo:%s/%s milestone:Go%s label:Security", constants.GolangOrgName, constants.GoRepoName, version)
		milestoneIssues, err := s.Ghc.FindIssuesWithOrg(constants.GolangOrgName, query, "", false)
		if err != nil {
			return fmt.Errorf("Find Golang Milestone: %v", err)
		}
		// for each of the issues(i) in milestoneIssues[] we want to pull the base issueNumber from the body all backports have the base issue listed in the body
		for _, i := range milestoneIssues {
			for _, biMatch := range issNumRe.FindAllString(i.Body, -1) {
				if m[biMatch] == 0 {
					//List the backport issue as the
					m[biMatch] = i.Number
				}
			}
		}
	}
	// For each of these base issue numbers retrieve the issue, and mirror the title and body + a tag to the upstream issue to be used later when auto backporting
	for biNum, bpINum := range m {
		// remove the # from the issue number and convert to string
		biInt, err := strconv.Atoi(biNum[1:])
		if err != nil {
			return fmt.Errorf("Converting issue number to int: %w", err)
		}
		baseIssue, err := s.Ghc.GetIssue(constants.GolangOrgName, constants.GoRepoName, biInt)
		if err != nil {
			return fmt.Errorf("Getting base issue(%s/%s#%d): %w", constants.GolangOrgName, constants.GoRepoName, biInt, err)
		}
		miNum, err := s.Ghc.CreateIssue(constants.AwsOrgName, constants.EksdBuildToolingRepoName, baseIssue.Title, mirrorIssueBody(baseIssue.Body, constants.GolangOrgName, constants.GoRepoName, bpINum), 0, nil, nil)
		if err != nil {
			return fmt.Errorf("Creating mirrored issue: %w", err)
		}
		l.Info(fmt.Sprintf("Created Issue: %s/%s#%d", constants.AwsOrgName, constants.EksdBuildToolingRepoName, miNum))
	}
	return nil
}
