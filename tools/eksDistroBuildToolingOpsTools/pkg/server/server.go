package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"

	"github.com/sirupsen/logrus"
	"k8s.io/test-infra/prow/config"
	"k8s.io/test-infra/prow/plugins"

	"k8s.io/test-infra/prow/git/v2"
	"k8s.io/test-infra/prow/github"
	"k8s.io/test-infra/prow/pluginhelp"
)

const PluginName = "eksdistroopstool"

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
	TokenGenerator func() []byte
	BotUser        *github.UserData
	Email          string

	Gc  git.ClientFactory
	Ghc githubClient
	Log *logrus.Entry

	// Labels to apply.
	Labels []string
	// Use prow to assign users issues.
	ProwAssignments bool
	// Allow anybody to request or trigger event.
	AllowAll bool
	// Create an issue on conflict.
	IssueOnConflict bool
	// Set a custom label prefix.
	LabelPrefix string

	Bare     *http.Client
	PatchURL string

	Repos              []github.Repo
	mapLock            sync.Mutex
	lockGolangPatchMap map[golangPatchReleaseRequest]*sync.Mutex
}

// ServeHTTP validates an incoming webhook and puts it into the event channel.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	eventType, eventGUID, payload, ok, _ := github.ValidateWebhook(w, r, s.TokenGenerator)
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
				s.Log.WithError(err).WithFields(l.Data).Info("Handle Issue Failed.")
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
	author := ie.Sender.Login
	title := ie.Issue.Title
	body := ie.Issue.Body

	// Do not create a new logger, its fields are re-used by the caller in case of errors
	*l = *l.WithFields(logrus.Fields{
		github.OrgLogField:  org,
		github.RepoLogField: repo,
		github.PrLogField:   num,
	})

	golangPatchMatches := golangPatchReleaseRe.FindAllStringSubmatch(ie.Issue.Title, -1)
	if len(golangPatchMatches) != 0 {
		if err := s.handleGolangPatchRelease(l, author, &ie.Issue, org, repo, title, body, num); err != nil {
			return fmt.Errorf("handle GolangPatchrelease: %w", err)
		}
	}
	//TODO: add golangMinorMatches := golangMinorReleaseRe.FindAllStringSubmatch(ie.Issue.Title, -1)
	//Regex for thisi is below.
	//var golangMinorReleaseRe = regexp.MustCompile(`(?m)^(?:Golang Minor Release:)\s+(.+)$`)

	return nil
}

// Created based off plugins.FormatICResponse
func FormatIEResponse(ie github.IssueEvent, s string) string {
	return plugins.FormatResponseRaw(ie.Issue.Title, ie.Issue.HTMLURL, ie.Sender.Login, s)
}

func (s *Server) createComment(l *logrus.Entry, org, repo string, num int, comment *github.IssueComment, resp string) error {
	if err := func() error {
		if comment != nil {
			return s.Ghc.CreateComment(org, repo, num, plugins.FormatICResponse(*comment, resp))
		}
		return s.Ghc.CreateComment(org, repo, num, fmt.Sprintf("In response to a upstreampick label: %s", resp))
	}(); err != nil {
		l.WithError(err).Warn("failed to create comment")
		return err
	}
	logrus.Debug("Created comment")
	return nil
}

// createIssue creates an issue on GitHub.
func (s *Server) createIssue(l *logrus.Entry, org, repo, title, body string, num int, comment *github.IssueComment, labels, assignees []string) error {
	issueNum, err := s.Ghc.CreateIssue(org, repo, title, body, 0, labels, assignees)
	if err != nil {
		return s.createComment(l, org, repo, num, comment, fmt.Sprintf("new issue could not be created for failed upstreampick: %v", err))
	}

	return s.createComment(l, org, repo, num, comment, fmt.Sprintf("new issue created for failed upstreampick: #%d", issueNum))
}
