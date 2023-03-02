package server

import (
	"fmt"
	"reflect"
	"sync"
	"testing"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/github"
)

var commentFormat = "%s/%s#%d %s"

type fghc struct {
	sync.Mutex
	iss      *github.Issue
	isMember bool

	comments   []string
	iComments  []github.IssueComment
	iLabels    []github.Label
	orgMembers []github.TeamMember
	issues     []github.Issue
}

func (f *fghc) AddLabel(org, repo string, number int, label string) error {
	f.Lock()
	defer f.Unlock()
	for i := range f.issues {
		if number == f.issues[i].Number {
			f.issues[i].Labels = append(f.issues[i].Labels, github.Label{Name: label})
		}
	}
	return nil
}

func (f *fghc) AssignIssue(org, repo string, number int, logins []string) error {
	var users []github.User
	for _, login := range logins {
		users = append(users, github.User{Login: login})
	}

	f.Lock()
	for i := range f.issues {
		if number == f.issues[i].Number {
			f.issues[i].Assignees = append(f.issues[i].Assignees, users...)
		}
	}
	defer f.Unlock()
	return nil
}

func (f *fghc) CreateComment(org, repo string, number int, comment string) error {
	f.Lock()
	defer f.Unlock()
	f.comments = append(f.comments, fmt.Sprintf(commentFormat, org, repo, number, comment))
	return nil
}

func (f *fghc) IsMember(org, user string) (bool, error) {
	f.Lock()
	defer f.Unlock()
	return f.isMember, nil
}

func (f *fghc) GetRepo(owner, name string) (github.FullRepo, error) {
	f.Lock()
	defer f.Unlock()
	return github.FullRepo{}, nil
}

func (f *fghc) CreateIssue(org, repo, title, body string, milestone int, labels, assignees []string) (int, error) {
	f.Lock()
	defer f.Unlock()

	var ghLabels []github.Label
	var ghAssignees []github.User

	num := len(f.issues) + 1

	for _, label := range labels {
		ghLabels = append(ghLabels, github.Label{Name: label})
	}

	for _, assignee := range assignees {
		ghAssignees = append(ghAssignees, github.User{Login: assignee})
	}

	f.issues = append(f.issues, github.Issue{
		Title:     title,
		Body:      body,
		Number:    num,
		Labels:    ghLabels,
		Assignees: ghAssignees,
	})

	return num, nil
}

func (f *fghc) ListIssueComments(org, repo string, number int) ([]github.IssueComment, error) {
	f.Lock()
	defer f.Unlock()
	return f.iComments, nil
}

func (f *fghc) GetIssueLabels(org, repo string, number int) ([]github.Label, error) {
	f.Lock()
	defer f.Unlock()
	return f.iLabels, nil
}

func (f *fghc) ListOrgMembers(org, role string) ([]github.TeamMember, error) {
	f.Lock()
	defer f.Unlock()
	if role != "all" {
		return nil, fmt.Errorf("all is only supported role, not: %s", role)
	}
	return f.orgMembers, nil
}

func (f *fghc) GetIssue(org, repo string, number int) (*github.Issue, error) {
	f.Lock()
	defer f.Unlock()
	return f.iss, nil
}

func (f *fghc) FindIssuesWithOrg(org, query, sort string, asc bool) ([]github.Issue, error) {
	f.Lock()
	defer f.Unlock()
	var iss []github.Issue
	iss = append(iss, f.issues...)
	for _, i := range f.issues {
		iss = append(iss, github.Issue{
			User:   i.User,
			Number: i.Number,
		})
	}
	return iss, nil
}

func TestUpstreamPickCreateIssue(t *testing.T) {
	t.Parallel()
	testCases := []struct {
		org       string
		repo      string
		title     string
		body      string
		prNum     int
		labels    []string
		assignees []string
	}{
		{
			org:       "istio",
			repo:      "istio",
			title:     "brand new feature",
			body:      "automated upstream-pick",
			prNum:     2190,
			labels:    nil,
			assignees: []string{"clarketm"},
		},
		{
			org:       "kubernetes",
			repo:      "kubernetes",
			title:     "alpha feature",
			body:      "automated upstream-pick",
			prNum:     3444,
			labels:    []string{"new", "1.18"},
			assignees: nil,
		},
	}

	errMsg := func(field string) string {
		return fmt.Sprintf("GH issue %q does not match: \nexpected: \"%%v\" \nactual: \"%%v\"", field)
	}

	for _, tc := range testCases {

		ghc := &fghc{}

		s := &Server{
			Ghc: ghc,
		}

		if err := s.createIssue(logrus.WithField("test", t.Name()), tc.org, tc.repo, tc.title, tc.body, tc.prNum, nil, tc.labels, tc.assignees); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(ghc.issues) < 1 {
			t.Fatalf("Expected 1 GH issue to be created but got: %d", len(ghc.issues))
		}

		ghIssue := ghc.issues[len(ghc.issues)-1]

		if tc.title != ghIssue.Title {
			t.Fatalf(errMsg("title"), tc.title, ghIssue.Title)
		}

		if tc.body != ghIssue.Body {
			t.Fatalf(errMsg("body"), tc.title, ghIssue.Title)
		}

		if len(ghc.issues) != ghIssue.Number {
			t.Fatalf(errMsg("number"), len(ghc.issues), ghIssue.Number)
		}

		var actualAssignees []string
		for _, assignee := range ghIssue.Assignees {
			actualAssignees = append(actualAssignees, assignee.Login)
		}

		if !reflect.DeepEqual(tc.assignees, actualAssignees) {
			t.Fatalf(errMsg("assignees"), tc.assignees, actualAssignees)
		}

		var actualLabels []string
		for _, label := range ghIssue.Labels {
			actualLabels = append(actualLabels, label.Name)
		}

		if !reflect.DeepEqual(tc.labels, actualLabels) {
			t.Fatalf(errMsg("labels"), tc.labels, actualLabels)
		}

		cpFormat := fmt.Sprintf(commentFormat, tc.org, tc.repo, tc.prNum, "In response to: %s")
		expectedComment := fmt.Sprintf(cpFormat, fmt.Sprintf("new issue created for: #%d", ghIssue.Number))
		actualComment := ghc.comments[len(ghc.comments)-1]

		if expectedComment != actualComment {
			t.Fatalf(errMsg("comment"), expectedComment, actualComment)
		}

	}
}
