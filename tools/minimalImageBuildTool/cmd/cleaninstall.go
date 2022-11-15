package cmd

import (
	"github.com/spf13/cobra"
)

var cleanInstallCmd = &cobra.Command{
	Use:   "install",
	Short: "",
	Long:  "",
}

func init() {
	cleanCmd.AddCommand(cleanInstallCmd)
}
