package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"sync"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/config"
	"k8s.io/test-infra/prow/plugins"

	"k8s.io/test-infra/prow/git/v2"
	"k8s.io/test-infra/prow/github"
	"k8s.io/test-infra/prow/pluginhelp"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
)

const pluginName = "eksdistroopstool"

type githubClient interface {
	AssignIssue(org, repo string, number int, logins []string) error
	CreateComment(org, repo string, number int, comment string) error
	CreateIssue(org, repo, title, body string, milestone int, labels, assignees []string) (int, error)
	FindIssuesWithOrg(org, query, sort string, asc bool) ([]github.Issue, error)
	GetIssue(org, repo string, number int) (*github.Issue, error)
	IsMember(org, user string) (bool, error)
}

// HelpProvider construct the pluginhelp.PluginHelp for this plugin.
func HelpProvider(_ []config.OrgRepo) (*pluginhelp.PluginHelp, error) {
	pluginHelp := &pluginhelp.PluginHelp{
		Description: `The golang patch release plugin is used for EKS-Distro automation creating issues of upstream Golang security fixes for EKS supported versions. For every successful golang patch release trigger, a new issue is created that mirrors upstream security issues and assigned to the requestor.`,
	}
	pluginHelp.AddCommand(pluginhelp.Command{
		Usage:       "Triggered off issues with |Golang Patch Release: | in title",
		Description: "Create issue that mirrors security issues when Patch/Security releases are announced.",
		Featured:    true,
		WhoCanUse:   "No use case. Follows automation",
		Examples:    []string{""},
	})
	return pluginHelp, nil
}

// Server implements http.Handler. It validates incoming GitHub webhooks and
// then dispatches them to the appropriate plugins.
type Server struct {
	tokenGenerator func() []byte
	botUser        *github.UserData
	email          string

	gc  git.ClientFactory
	ghc githubClient
	log *logrus.Entry

	// Labels to apply to the backported issue.
	labels []string
	// Use prow to assign users to backported issue.
	prowAssignments bool
	// Allow anybody to do backports.
	allowAll bool
	// Create an issue on upstreampick conflict.
	issueOnConflict bool
	// Set a custom label prefix.
	labelPrefix string

	bare     *http.Client
	patchURL string

	repos   []github.Repo
	mapLock sync.Mutex
	lockMap map[upstreamIssuePickRequest]*sync.Mutex
}

type upstreamIssuePickRequest struct {
	org    string
	repo   string
	issNum int
}

// ServeHTTP validates an incoming webhook and puts it into the event channel.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	eventType, eventGUID, payload, ok, _ := github.ValidateWebhook(w, r, s.tokenGenerator)
	if !ok {
		return
	}
	fmt.Fprint(w, "Event received. Have a nice day.")

	if err := s.handleEvent(eventType, eventGUID, payload); err != nil {
		logrus.WithError(err).Error("Error parsing event.")
	}
}

func (s *Server) handleEvent(eventType, eventGUID string, payload []byte) error {
	l := logrus.WithFields(logrus.Fields{
		"event-type":     eventType,
		github.EventGUID: eventGUID,
	})
	switch eventType {
	case "issues":
		var ie github.IssueEvent
		if err := json.Unmarshal(payload, &ie); err != nil {
			return err
		}
		go func() {
			if err := s.handleIssue(l, ie); err != nil {
				s.log.WithError(err).WithFields(l.Data).Info("Issue creation failed.")
			}
		}()
	default:
		logrus.Debugf("skipping event of type %q", eventType)
	}
	return nil
}

func (s *Server) handleIssue(l *logrus.Entry, ie github.IssueEvent) error {
	// Only consider newly opened issues and not PRs
	if ie.Action != github.IssueActionOpened && !ie.Issue.IsPullRequest() {
		return nil
	}

	org := ie.Repo.Owner.Login
	repo := ie.Repo.Name
	num := ie.Issue.Number
	auth := ie.Sender.Login
	title := ie.Issue.Title
	body := ie.Issue.Body

	// Do not create a new logger, its fields are re-used by the caller in case of errors
	*l = *l.WithFields(logrus.Fields{
		github.OrgLogField:  org,
		github.RepoLogField: repo,
		github.PrLogField:   num,
	})

	if auth != constants.EksDistroBotName || !s.allowAll {
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

	//Currently handling Golang Patch Releases and Golang Minor Releases
	var golangPatchReleaseRe = regexp.MustCompile(`(?m)^(?:Golang Patch Release:)\s+(.+)$`)

	golangPatchMatches := golangPatchReleaseRe.FindAllStringSubmatch(ie.Issue.Title, -1)
	if len(golangPatchMatches) != 0 {
		if err := s.handle(l, ie.Issue.User.Login, &ie.Issue, org, repo, title, body, num); err != nil {
			return fmt.Errorf("handle GolangPatchrelease: %w", err)
		}
	}
	//TODO: add golangMinorMatches := golangMinorReleaseRe.FindAllStringSubmatch(ie.Issue.Title, -1)
	//Regex for thisi is below.
	//var golangMinorReleaseRe = regexp.MustCompile(`(?m)^(?:Golang Minor Release:)\s+(.+)$`)

	return nil
}

func (s *Server) handle(logger *logrus.Entry, requestor string, issue *github.Issue, org, repo, title, body string, num int) error {
	var lock *sync.Mutex
	func() {
		s.mapLock.Lock()
		defer s.mapLock.Unlock()
		if _, ok := s.lockMap[upstreamIssuePickRequest{org, repo, num}]; !ok {
			if s.lockMap == nil {
				s.lockMap = map[upstreamIssuePickRequest]*sync.Mutex{}
			}
			s.lockMap[upstreamIssuePickRequest{org, repo, num}] = &sync.Mutex{}
		}
		lock = s.lockMap[upstreamIssuePickRequest{org, repo, num}]
	}()
	lock.Lock()
	defer lock.Unlock()

	if err := s.HandleGolangPatchRelease(logger, issue); err != nil {
		return fmt.Errorf("failed to handle Golang Patch Release: %w", err)
	}

	return nil
}

// Created based off plugins.FormatICResponse
func FormatIEResponse(ie github.IssueEvent, s string) string {
	return plugins.FormatResponseRaw(ie.Issue.Title, ie.Issue.HTMLURL, ie.Sender.Login, s)
}

func (s *Server) HandleGolangPatchRelease(l *logrus.Entry, upIss *github.Issue) error {
	var golangVersionsRe = regexp.MustCompile(`(?m)(\d+.\d+.\d+)`)
	var issNumRe = regexp.MustCompile(`(#\d+)`)
	m := make(map[string]int)
	for _, version := range golangVersionsRe.FindAllString(upIss.Title, -1) {
		query := fmt.Sprintf("repo:%s/%s milestone:Go%s label:Security", constants.GolangOrgName, constants.GoRepoName, version)
		milestoneIssues, err := s.ghc.FindIssuesWithOrg(constants.GolangOrgName, query, "", false)
		if err != nil {
			return fmt.Errorf("Find Golang Milestone: %v", err)
		}
		for _, i := range milestoneIssues {
			for _, biMatch := range issNumRe.FindAllString(i.Body, -1) {
				if m[biMatch] == 0 {
					m[biMatch] = 1
				}
			}
			return nil
		}
	}
	for biNum := range m {
		biInt, err := strconv.Atoi(biNum)
		if err != nil {
			return fmt.Errorf("Converting issue number to int: %w", err)
		}
		baseIssue, err := s.ghc.GetIssue(constants.GolangOrgName, constants.GoRepoName, biInt)
		if err != nil {
			return fmt.Errorf("Getting base issue(%s/%s#%d): %w", constants.GolangOrgName, constants.GoRepoName, biInt, err)
		}
		miNum, err := s.ghc.CreateIssue(constants.AwsOrgName, constants.EksdBuildToolingRepoName, baseIssue.Title, baseIssue.Body, 0, nil, nil)
		if err != nil {
			return fmt.Errorf("Creating mirrored issue: %w", err)
		}
		l.Info(fmt.Sprintf("Created Issue: %s/%s#%d", constants.AwsOrgName, constants.EksdBuildToolingRepoName, miNum))
	}
	return nil
}

func (s *Server) createComment(l *logrus.Entry, org, repo string, num int, comment *github.IssueComment, resp string) error {
	if err := func() error {
		if comment != nil {
			return s.ghc.CreateComment(org, repo, num, plugins.FormatICResponse(*comment, resp))
		}
		return s.ghc.CreateComment(org, repo, num, fmt.Sprintf("In response to a upstreampick label: %s", resp))
	}(); err != nil {
		l.WithError(err).Warn("failed to create comment")
		return err
	}
	logrus.Debug("Created comment")
	return nil
}

// createIssue creates an issue on GitHub.
func (s *Server) createIssue(l *logrus.Entry, org, repo, title, body string, num int, comment *github.IssueComment, labels, assignees []string) error {
	issueNum, err := s.ghc.CreateIssue(org, repo, title, body, 0, labels, assignees)
	if err != nil {
		return s.createComment(l, org, repo, num, comment, fmt.Sprintf("new issue could not be created for failed upstreampick: %v", err))
	}

	return s.createComment(l, org, repo, num, comment, fmt.Sprintf("new issue created for failed upstreampick: #%d", issueNum))
}
