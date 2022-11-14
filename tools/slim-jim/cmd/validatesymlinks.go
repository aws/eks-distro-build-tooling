package cmd

import (
	"github.com/spf13/cobra"
)

var validateSymlinksCmd = &cobra.Command{
	Use:   "Symlinks",
	Short: "Validate all symlinks",
	Long:  "Validate all symlinks",
}

func init() {
	validateCmd.AddCommand(validateSymlinksCmd)
}