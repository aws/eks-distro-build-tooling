package cmd

import (
	"github.com/spf13/cobra"
)

var installBinaryCmd = &cobra.Command{
	Use:   "binary",
	Short: "",
	Long:  "",
}

func init() {
	installCmd.AddCommand(installBinaryCmd)
}
