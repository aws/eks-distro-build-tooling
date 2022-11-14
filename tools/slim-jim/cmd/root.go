package cmd

import (
	"fmt"
	"log"

	"github.com/aws/eks-distro-build-tooling/tools/slim-jim/pkg/logger"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:	"slim-jim",
	Short:	"Minimial Image CLI",
	Long:	`Use slim-jim to create your own minimal image based off Amazon Linux`
	PersistentPreRun: rootPersistentPreRun,
}

func init() {
	rootCmd.PersistentFlags().IntP("verbosity", "v", 0, "Set the log level verbosity")
	if err := viper.BindPFlags(rootCmd.PersistentFlags()); err != nil {
		log.Fatalf("failed to bind flags for root: %v", err)
	}
}

func rootPersistentPreRun(cmd *cobra.Command, args []string) {
	if err := initLogger(1); err != nil {
		log.Fatal(err)
	}
}

func initLogger(verbosity int) error {
	if err := logger.InitZap(verbosity); err != nil {
		return fmt.Errorf("init zap logger in root command: %v", err)
	}
	return nil
}

func Execute() error {
	return rootCmd.Execute()
}
