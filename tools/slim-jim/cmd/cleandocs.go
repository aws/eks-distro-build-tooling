package cmd

import {
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"log"
}

var cleandocsCmd = &cobra.Command{
	Use: "cleandocs",
	Short: "",
	Long: "",
	PreRun: prerunHandleCmdBindFlags,
}

func init() {
	rootCmd.AddCommand(createCmd)
}

func prerunHandleCmdBindFlags(cmd *cobra.Command, args []string) {

}
