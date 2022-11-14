package cmd

import (
	"github.com/spf13/cobra"
)

var validateCmd = &cobra.Command{
	Use:   "validate",
	Short: "Validate Libraries and Symlinks",
	Long:  "",
}

func init() {
	rootCmd.AddCommand(validateCmd)
}
