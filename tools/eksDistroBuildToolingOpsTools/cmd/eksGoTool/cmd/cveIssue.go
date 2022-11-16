package cmd

import (
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/issueManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

var createCveIssue = &cobra.Command{
	Use:   "createCveIssue [-ci] [-c value] [-i value]",
	Short: "Create new top level CVE Issue",
	Long:  `Create a new top level CVE Issue in aws/eks-distro-build-tooling`,
	RunE: func(cmd *cobra.Command, args []string) error {

		owner := "aws"
		repo := "eks-distro-build-tooling"

		retrier := retrier.New(time.Second*380, retrier.WithBackoffFactor(1.5), retrier.WithMaxRetries(15, time.Second*30))

		token, err := github.GetGithubToken()
		if err != nil {
			return fmt.Errorf("getting Github PAT from environment at variable %s: %v", github.PersonalAccessTokenEnvVar, err)
		}
		githubClient, err := github.NewClient(cmd.Context(), token)
		if err != nil {
			return fmt.Errorf("setting up Github client: %v", err)
		}

		// set up PR Creator Handler
		//o := &prmanager.Opts{
		//	SourceOwner: owner,
		//	SourceRepo:  repo,
		//	PrRepo:      repo,
		//	PrRepoOwner: owner,
		//}
		// prCreator := prmanager.New(retrier, githubClient, o)

		// set up Issue Creator handler
		issueManagerOpts := &issueManager.Opts{
			SourceOwner: owner,
			SourceRepo:  repo,
		}
		issueManager := issueManager.New(retrier, githubClient, issueManagerOpts)

		issueOpts := &issueManager.CreateIssueOpts{
			Title:    "Title",
			Body:     "Body",
			Labels:   []string{"security"},
			Assignee: "rcrozean",
			State:    "open",
		}

		issueManager.CreateIssue(cmd.Context(), issueOpts)
		return nil
	},
}
