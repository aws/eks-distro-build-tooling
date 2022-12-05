package cmd

import (
	"github.com/spf13/cobra"
)

const ()

var (
	backportPrCmd = &cobra.Command{
		Use:   "pr",
		Short: "Opens backport prs for backport level issues",
		Long:  `Opens prs with a template Title and Body for backport level issues to EKS-Distro-Build-Tooling supported versions of Golang`,
		RunE: func(cmd *cobra.Command, args []string) error {
			// set up PR Creator Handler
			//o := &prmanager.Opts{
			//	SourceOwner: owner,
			//	SourceRepo:  repo,
			//	PrRepo:      repo,
			//	PrRepoOwner: owner,
			//}
			//prCreator := prmanager.New(retrier, githubClient, o)

			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(backportPrCmd)
}
