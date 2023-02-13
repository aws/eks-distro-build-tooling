package main

import (
	"context"
	"fmt"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/issueManager"
)

func CopyIssue(ctx context.Context, im *issueManager.IssueManager, org string, repo string, issueNumber int) error {
	giOpts := &issueManager.GetIssueOpts{
		Owner: org,
		Repo:  repo,
		Issue: issueNumber,
	}
	err := im.GetIssue(ctx, giOpts)
	if err != nil {
		return fmt.Errorf("Getting issue %s/%s#%d: %w", giOpts.Owner, giOpts.Repo, giOpts.Issue, err)
	}

}
