package cmd

import {
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"log"
}

var validateCmd = &cobra.Command{
	Use: "validate",
	Short: "Validate Libraries and Symlinks",
	Long: "",
	PreRun: prerunHandleCmdBindFlags,
}

func init() {
	rootCmd.AddCommand(createCmd)
}

func prerunHandleCmdBindFlags(cmd *cobra.Command, args []string) {

}
