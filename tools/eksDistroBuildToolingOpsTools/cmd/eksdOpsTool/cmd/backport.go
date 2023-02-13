package cmd

import "github.com/spf13/cobra"

var (
	backportCmd = &cobra.Command{
		Use:   "backport",
		Short: "Commit backport automation",
		Long:  "Tool for backporting commits and managing the backport process in version control",
	}
)

func init() {
	rootCmd.AddCommand(backportCmd)
}
