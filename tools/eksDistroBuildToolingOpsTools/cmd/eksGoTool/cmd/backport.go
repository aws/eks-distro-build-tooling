package cmd

import "github.com/spf13/cobra"

var (
	backportCmd = &cobra.Command{
		Use:   "backport [command]",
		Short: "",
		Long:  ``,
	}
)

func init() {
	rootCmd.AddCommand(backportCmd)
}
