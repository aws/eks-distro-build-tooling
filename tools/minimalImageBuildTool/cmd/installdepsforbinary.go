package cmd

import (
	"github.com/spf13/cobra"
)

var installDepsForBinaryCmd = &cobra.Command{
	Use:   "deps",
	Short: "",
	Long:  "",
}

func init() {
	installCmd.AddCommand(installDepsForBinaryCmd)
}
