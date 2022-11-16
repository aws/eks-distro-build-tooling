package cmd

import (
	"github.com/spf13/cobra"
)

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "",
	Long:  "",
}

func init() {
	rootCmd.AddCommand(installCmd)
}
