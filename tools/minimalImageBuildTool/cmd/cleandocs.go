package cmd

import (
	"github.com/spf13/cobra"
)

var cleandocsCommand = &cobra.Command{
	Use:   "docs",
	Short: "",
	Long:  "",
}

func init() {
	cleanCmd.AddCommand(cleandocsCmd)
}
