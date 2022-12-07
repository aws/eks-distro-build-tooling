package github

import (
	"context"
	"fmt"

	"github.com/google/go-github/v48/github"
	"golang.org/x/oauth2"
)

type Client struct {
	Git          GitClient
	Repositories RepoClient
	PullRequests PullRequestClient
	Issues       IssueClient
}

type GitClient interface {
	GetRef(ctx context.Context, owner string, repo string, ref string) (*github.Reference, *github.Response, error)
	CreateRef(ctx context.Context, owner string, repo string, ref *github.Reference) (*github.Reference, *github.Response, error)
	CreateTree(ctx context.Context, owner string, repo string, baseTree string, entries []*github.TreeEntry) (*github.Tree, *github.Response, error)
	CreateCommit(ctx context.Context, owner string, repo string, commit *github.Commit) (*github.Commit, *github.Response, error)
	UpdateRef(ctx context.Context, owner string, repo string, ref *github.Reference, force bool) (*github.Reference, *github.Response, error)
}

type RepoClient interface {
	GetCommit(ctx context.Context, owner, repo, sha string, opts *github.ListOptions) (*github.RepositoryCommit, *github.Response, error)
	GetContents(ctx context.Context, owner, repo, path string, opts *github.RepositoryContentGetOptions) (fileContent *github.RepositoryContent, directoryContent []*github.RepositoryContent, resp *github.Response, err error)
}

type PullRequestClient interface {
	Get(ctx context.Context, owner string, repo string, number int) (*github.PullRequest, *github.Response, error)
	Create(ctx context.Context, owner string, repo string, pull *github.NewPullRequest) (*github.PullRequest, *github.Response, error)
	List(ctx context.Context, owner string, repo string, opts *github.PullRequestListOptions) ([]*github.PullRequest, *github.Response, error)
}

type IssueClient interface {
	Create(ctx context.Context, owner string, repo string, issue *github.IssueRequest) (*github.Issue, *github.Response, error)
	Get(ctx context.Context, owner string, repo string, issueNum int) (*github.Issue, *github.Response, error)
}

func NewClient(ctx context.Context, personalAccessToken string) (*Client, error) {
	if personalAccessToken == "" {
		return nil, fmt.Errorf("no personal access token provided when instantiating Github client")
	}
	ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: personalAccessToken})
	tc := oauth2.NewClient(ctx, ts)
	c := github.NewClient(tc)
	client := &Client{
		Git:          c.Git,
		Repositories: c.Repositories,
		PullRequests: c.PullRequests,
		Issues:       c.Issues,
	}
	return client, nil
}
