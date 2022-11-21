package cmd

import (
	"github.com/spf13/cobra"
)

var installRpmCmd = &cobra.Command{
	Use:   "rpm",
	Short: "",
	Long:  "",
}

func init() {
	installCmd.AddCommand(installRpmCmd)
}
