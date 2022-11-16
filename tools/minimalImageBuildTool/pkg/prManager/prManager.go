package prmanager

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	gogithub "github.com/google/go-github/v48/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

type PrCreator struct {
	client       *github.Client
	sourceOwner  string
	sourceRepo   string
	prRepo       string
	prRepoOwner  string
	retrier      *retrier.Retrier
}

type Opts struct {
	SourceOwner string
	SourceRepo  string
	PrRepo      string
	PrRepoOwner string
}

func New(retrier *retrier.Retrier, client *github.Client, opts *Opts) *PrCreator {
	return &PrCreator{
		client:      client,
		sourceOwner: opts.SourceOwner,
		sourceRepo:  opts.SourceRepo,
		prRepo:      opts.PrRepo,
		prRepoOwner: opts.PrRepoOwner,
		retrier:     retrier,
	}
}

// getRef returns the commit branch reference object if it exists or creates it
// from the base branch before returning it.
func (p *PrCreator) getRef(ctx context.Context, commitBranch string, baseBranch string) (ref *gogithub.Reference, err error) {
	if ref, _, err = p.client.Git.GetRef(ctx, p.sourceOwner, p.sourceRepo, "refs/heads/" + commitBranch); err == nil {
		return ref, nil
	}

	if commitBranch == baseBranch {
		return nil, errors.New("the commit-branch does not exist but base-branch is the same as commit-branch")
	}

	var baseRef *gogithub.Reference
	if baseRef, _, err = p.client.Git.GetRef(ctx, p.sourceOwner, p.sourceRepo, "refs/heads/" + baseBranch); err != nil {
		return nil, err
	}
	newRef := &gogithub.Reference{Ref: gogithub.String("refs/heads/" + commitBranch), Object: &gogithub.GitObject{SHA: baseRef.Object.SHA}}
	ref, _, err = p.client.Git.CreateRef(ctx, p.sourceOwner, p.sourceRepo, newRef)
	return ref, err
}

// getTree generates the tree to commit based on the given files and the commit
// of the ref you got in getRef.
func (p *PrCreator) getTree(ctx context.Context, ref *gogithub.Reference, sourceFileBody []byte, destFilePath string) (tree *gogithub.Tree, err error) {
	// Create a tree with what to commit.
	entries := []*gogithub.TreeEntry{}
	entries = append(entries, &gogithub.TreeEntry{Path: gogithub.String(destFilePath), Type: gogithub.String("blob"), Content: gogithub.String(string(sourceFileBody)), Mode: gogithub.String("100644")})

	tree, _, err = p.client.Git.CreateTree(ctx, p.sourceOwner, p.sourceRepo, *ref.Object.SHA, entries)
	return tree, err
}

// pushCommit creates the commit in the given reference using the given tree.
func (p *PrCreator) pushCommit(ctx context.Context, ref *gogithub.Reference, tree *gogithub.Tree, authorName string, authorEmail string, commitMessage string) (err error) {
	// Get the parent commit to attach the commit to.
	parent, _, err := p.client.Repositories.GetCommit(ctx, p.sourceOwner, p.sourceRepo, *ref.Object.SHA, nil)
	if err != nil {
		return err
	}
	// This is not always populated, but is needed.
	parent.Commit.SHA = parent.SHA

	// Create the commit using the tree.
	date := time.Now()
	author := &gogithub.CommitAuthor{
		Date: &date,
		Name: &authorName,
		Email: &authorEmail,
	}

	commit := &gogithub.Commit{
		Author: author,
		Message: &commitMessage,
		Tree: tree,
		Parents: []*gogithub.Commit{
			parent.Commit,
		},
	}
	newCommit, _, err := p.client.Git.CreateCommit(ctx, p.sourceOwner, p.sourceRepo, commit)
	if err != nil {
		return err
	}

	// Attach the commit to the master branch.
	ref.Object.SHA = newCommit.SHA
	_, _, err = p.client.Git.UpdateRef(ctx, p.sourceOwner, p.sourceRepo, ref, false)
	return err
}

func (p *PrCreator) getPr(ctx context.Context, opts *GetPrOpts) (*gogithub.PullRequest, error) {
	o := &gogithub.PullRequestListOptions{
		Head:        fmt.Sprintf("%v:%v", p.prRepoOwner, opts.CommitBranch),
		Base:        opts.BaseBranch,
	}
	list, r, err := p.client.PullRequests.List(ctx, p.prRepoOwner, p.prRepo, o)
	if err != nil {
		if r != nil {
			logger.V(3).Info("listing pr response", "status code", r.Response.StatusCode)
		}
		return nil, fmt.Errorf("getting open PR into %v from %v: listing PR: %v", opts.BaseBranch, opts.CommitBranch, err)
	}
	if len(list) > 1 {
		return nil, fmt.Errorf("getting open PR into %v from %v: open PR list is greater than 1, this is impossible or wrong. PR list length: %d", opts.BaseBranch, opts.CommitBranch, len(list))
	}
	if len(list) == 0 {
		return nil, nil
	}
	prNumber := *list[0].Number
	pr, r, err := p.client.PullRequests.Get(ctx, p.prRepoOwner, p.sourceRepo, prNumber)
	if err != nil {
		if r != nil {
			logger.V(3).Info("getting pr response", "status code", r.Response.StatusCode)
		}
		return nil, fmt.Errorf("getting open PR number %d: %v", prNumber, err)
	}
	return pr, nil
}

func (p *PrCreator) createPR(ctx context.Context, opts *CreatePrOpts) (pr *gogithub.PullRequest, err error) {
	if opts.PrSubject == "" {
		return nil, fmt.Errorf("PR subject is required")
	}

	if p.prRepoOwner != "" && p.prRepoOwner != p.sourceOwner {
		opts.CommitBranch = fmt.Sprintf("%s:%s", p.sourceOwner, opts.CommitBranch)
	} else {
		p.prRepoOwner = p.sourceOwner
	}

	if p.prRepo == "" {
		p.prRepo = p.sourceRepo
	}

	newPR := &gogithub.NewPullRequest{
		Title:               &opts.PrSubject,
		Head:                &opts.CommitBranch,
		Base:                &opts.PrBranch,
		Body:                &opts.PrDescription,
		MaintainerCanModify: gogithub.Bool(true),
	}

	var pullRequest *gogithub.PullRequest
	var resp *gogithub.Response
	err = p.retrier.Retry(func() error {
		pullRequest, resp, err = p.client.PullRequests.Create(ctx, p.prRepoOwner, p.prRepo, newPR)
		if resp.StatusCode == github.SecondaryRateLimitStatusCode {
			if strings.Contains(err.Error(), github.SecondaryRateLimitResponse) {
				return fmt.Errorf("rate limited while attempting to create github pull request: %v", err)
			}
		}
		if err != nil && strings.Contains(err.Error(), github.PullRequestAlreadyExistsForBranchError) {
			// there can only be one PR per branch; if there's already an existing PR for the branch, we won't create one, but continue
			logger.V(1).Info("A Pull Request already exists for the given branch", "branch", opts.CommitBranch)
			getPrOpts := &GetPrOpts{
				CommitBranch:  opts.CommitBranch,
				BaseBranch:   "main",
			}
			pullRequest, err = p.getPr(ctx, getPrOpts)
			if err != nil {
				return err
			}
			return nil
		}
		if err != nil {
			return fmt.Errorf("creating Github pull request: %v; resp: %v", err, resp)
		}
		logger.V(1).Info("Github Pull Request Created", "Pull Request URL", pullRequest.GetHTMLURL())
		return nil
	})
	if err != nil {
		return  nil, fmt.Errorf("creating github pull request: %v", err)
	}
	logger.V(4).Info("sleeping after PR creation to avoid secondary rate limiting by Github content API")
	time.Sleep(time.Second * 1)
	return pullRequest, nil
}

type CreatePrOpts struct {
	CommitBranch    string
	BaseBranch      string
	AuthorName      string
	AuthorEmail     string
	CommitMessage   string
	PrSubject       string
	PrBranch        string
	PrDescription   string
	DestFileGitPath string
	SourceFileBody []byte
}

func (p *PrCreator) CreatePr(ctx context.Context, opts *CreatePrOpts) (string, error) {
	ref, err := p.getRef(ctx, opts.CommitBranch, opts.BaseBranch)
	if err != nil {
		return "", fmt.Errorf("creating pull request: get/create the commit reference: %s\n", err)
	}
	if ref == nil {
		return "", fmt.Errorf("creating pull request: the reference is nil")
	}

	tree, err := p.getTree(ctx, ref, opts.SourceFileBody, opts.DestFileGitPath)
	if err != nil {
		return "", fmt.Errorf("creating the tree based on the provided files: %s\n", err)
	}

	if err := p.pushCommit(ctx, ref, tree, opts.AuthorName, opts.AuthorEmail, opts.CommitMessage); err != nil {
		return "", fmt.Errorf("creating the commit: %s\n", err)
	}

	pr, err := p.createPR(ctx, opts); if err != nil {
		return "", fmt.Errorf("creating pull request: %s", err)
	}
	return pr.GetHTMLURL(), nil
}

type GetPrOpts struct {
	CommitBranch string
	BaseBranch   string
}

func (p *PrCreator) GetPr(ctx context.Context, opts *GetPrOpts) (string, error) {
	pr, err := p.getPr(ctx, opts); if err != nil {
		return "", fmt.Errorf("getting pull request: %s", err)
	}
	return pr.GetHTMLURL(), nil
}