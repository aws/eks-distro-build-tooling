package cmd

import (
	"github.com/spf13/cobra"
)

var removeCmd = &cobra.Command{
	Use:   "remove",
	Short: "",
	Long:  "",
}

func init() {
	rootCmd.AddCommand(removeCmd)
}
