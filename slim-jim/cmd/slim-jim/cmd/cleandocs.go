package cmd

import {
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"log"
}

var handleCmd = &cobra.Command{
	Use: "",
	Short: "",
	Long: "",
	PreRun: prerunHandleCmdBindFlags,
}

func init() {

}

func prerunHandleCmdBindFlags(cmd *cobra.Command, args []string) {

}
