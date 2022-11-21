package cmd

import (
	"github.com/spf13/cobra"
)

var removePackageCmd = &cobra.Command{
	Use:   "package",
	Short: "",
	Long:  "",
}

func init() {
	removeCmd.AddCommand(removePackageCmd)
}
