package repoManager

import (
	"context"
	"fmt"
	"io"
	"strings"

	gogithub "github.com/google/go-github/v48/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

type RepoContentManager struct {
	client      *github.Client
	sourceOwner string
	sourceRepo  string
	retrier     *retrier.Retrier
}

type Opts struct {
	SourceOwner string
	SourceRepo  string
}

func New(r *retrier.Retrier, githubClient *github.Client, opts *Opts) *RepoContentManager {
	return &RepoContentManager{
		client:      githubClient,
		sourceOwner: opts.SourceOwner,
		sourceRepo:  opts.SourceRepo,
		retrier:     r,
	}
}

type GetFileOpts struct {
	Owner string
	Repo  string
	Path  string
	Ref   *gogithub.RepositoryContentGetOptions // Can be a SHA, branch, or tag. Optional
}

func (p *RepoContentManager) GetFile(ctx context.Context, opts *GetFileOpts) (*gogithub.RepositoryContent, error) {
	var fileContent *gogithub.RepositoryContent
	var resp *gogithub.Response
	var err error
	fileContent, _, resp, err = p.client.Repositories.GetContents(ctx, opts.Owner, opts.Repo, opts.Path, opts.Ref)
	if resp != nil {
		if resp.StatusCode == github.SecondaryRateLimitStatusCode {
			b, err := io.ReadAll(resp.Body)
			if err != nil {
				return nil, fmt.Errorf("reading Github response body: %v", err)
			}
			if strings.Contains(string(b), github.SecondaryRateLimitResponse) {
				logger.V(4).Info("rate limited while attempting to get github file")
				return nil, fmt.Errorf("rate limited while attempting to get github file: %v", err)
			}
		}

		if resp.StatusCode == github.ResourceGoneStatusCode {
			_, err := io.ReadAll(resp.Body)
			if err != nil {
				return nil, fmt.Errorf("reading Github response body: %v", err)
			}
		}
	}
	if err != nil {
		logger.V(4).Error(err, "getting file from Github", "response", resp)
		return nil, fmt.Errorf("getting file from Github: %v; resp: %v", err, resp)
	}
	logger.V(4).Info("get file response", "response", resp.Response.StatusCode)
	logger.V(1).Info("Github file received", "fileContent URL", fileContent.GetHTMLURL())
	return fileContent, nil
}
