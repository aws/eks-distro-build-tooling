package cmd

import (
	"github.com/spf13/cobra"
)

var validateLibrariesCmd = &cobra.Command{
	Use:   "libraries",
	Short: "Validate all executables and libraries have all dependencies",
	Long:  "Validate all executables and libraries have all dependencies",
}

func init() {
	validateCmd.AddCommand(validateLibrariesCmd)
}
