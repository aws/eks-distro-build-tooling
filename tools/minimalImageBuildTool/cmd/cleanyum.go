package cmd

import (
	"github.com/spf13/cobra"
)

var cleanYumCmd = &cobra.Command{
	Use:   "yum",
	Short: "",
	Long:  "",
}

func init() {
	cleanCmd.AddCommand(cleanYumCmd)
}
