package issueManager

import (
	"context"
	"fmt"
	"io/ioutil"
	"strings"
	"time"

	gogithub "github.com/google/go-github/v48/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

type IssueManager struct {
	client      *github.Client
	sourceOwner string
	sourceRepo  string
	retrier     *retrier.Retrier

}

type Opts struct {
	SourceOwner string
	SourceRepo  string
}

func New(r *retrier.Retrier, githubClient *github.Client, opts *Opts) *IssueManager {
	return &IssueManager{
		client:      githubClient,
		sourceOwner: opts.SourceOwner,
		sourceRepo:  opts.SourceRepo,
		retrier:     r,
	}
}

type CreateIssueOpts struct {
	Title    *string
	Body     *string
	Labels   *[]string
	Assignee *string
	State    *string
}

func (p *IssueManager) CreateIssue(ctx context.Context, opts *CreateIssueOpts) (*gogithub.Issue, error) {
	i := &gogithub.IssueRequest{
		Title:     opts.Title,
		Body:      opts.Body,
		Labels:    opts.Labels,
		Assignee:  opts.Assignee,
		State:     opts.State,
	}

	var issue *gogithub.Issue
	var resp *gogithub.Response
	var err error
	issue, resp, err = p.client.Issues.Create(ctx, p.sourceOwner, p.sourceRepo, i)
	if resp != nil {
		if resp.StatusCode == github.SecondaryRateLimitStatusCode {
			b, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				return nil, fmt.Errorf("reading Github response body: %v", err)
			}
			if strings.Contains(string(b), github.SecondaryRateLimitResponse) {
				logger.V(4).Info("rate limited while attempting to create github issue")
				return nil, fmt.Errorf("rate limited while attempting to create github issues: %v", err)
			}
		}

		if resp.StatusCode == github.ResourceGoneStatusCode {
			b, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				return nil, fmt.Errorf("reading Github response body: %v", err)
			}
			if strings.Contains(string(b), github.IssuesDisabledForRepoResponse) {
				logger.V(4).Info("Can't create an issue, issues are disabled for repo", "repo", p.sourceRepo)
				return nil, fmt.Errorf("creating Github issue: issues are disabled for repo. error: %v, response: %v", err, resp)
			}
		}
	}
	if err != nil {
		logger.V(4).Error(err, "creating Github issue", "response", resp)
		return nil, fmt.Errorf("creating Github issue: %v; resp: %v", err, resp)
	}
	logger.V(4).Info("create issue response", "response", resp.Response.StatusCode)
	logger.V(1).Info("Github issue created", "issue URL", issue.GetHTMLURL())
	logger.V(4).Info("sleeping after Issue creation to avoid secondary rate limiting by Github content API")
	time.Sleep(time.Second * 1)
	return issue, nil
}