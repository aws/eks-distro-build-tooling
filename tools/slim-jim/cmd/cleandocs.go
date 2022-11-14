package cmd

import (
	"github.com/spf13/cobra"
)

var cleandocsCmd = &cobra.Command{
	Use:   "cleandocs",
	Short: "",
	Long:  "",
}

func init() {
	rootCmd.AddCommand(cleandocsCmd)
}
