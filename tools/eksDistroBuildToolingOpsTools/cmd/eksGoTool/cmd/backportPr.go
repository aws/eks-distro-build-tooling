package cmd

import (
	prmanager "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
	"github.com/spf13/cobra"
)

const ()

var (
	backportIssueCmd = &cobra.Command{
		Use:   "backport",
		Short: "Opens backport issues for top level github issue",
		Long:  `Opens issues to backport top level issue to EKS-Distro supported versions of Golang`,
		RunE: func(cmd *cobra.Command, args []string) error {
			issueUrl := args[0]

			// set up PR Creator Handler
			o := &prmanager.Opts{
				SourceOwner: owner,
				SourceRepo:  repo,
				PrRepo:      repo,
				PrRepoOwner: owner,
			}
			prCreator := prmanager.New(retrier, githubClient, o)

			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(backportIssue)
}
