package cmd

import (
	"context"
	"fmt"
	"log"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/pkg/logger"
)

const (
	allConsumersFlag = "allConsumers"
	eksDistroReleasesFlag = "eksDistroReleases"
)

var (
	rootCmd = &cobra.Command{
		Use:              "eksDistroConsumerUpdater",
		Short:            "Amazon EKS Distro downstream consumer updater",
		Long:             `Tools for updating EKS Distro consumers and notifiying them of new releases`,
		PersistentPreRun: rootPersistentPreRun,
	}
)

func init() {
	rootCmd.PersistentFlags().IntP("verbosity", "v", 0, "Set the log level verbosity")
	rootCmd.PersistentFlags().Bool(allConsumersFlag, true, "Rebuild all consumers")
	rootCmd.PersistentFlags().StringSlice(eksDistroReleasesFlag, []string{}, "EKS Distro releases to update consumers for")

	// Bind config flags to viper
	if err := viper.BindPFlags(rootCmd.PersistentFlags()); err != nil {
		log.Fatalf("failed to bind persistent flags for root: %v", err)
	}
}

func rootPersistentPreRun(cmd *cobra.Command, args []string) {
	if err := initLogger(); err != nil {
		log.Fatal(err)
	}
}

func initLogger() error {
	if err := logger.InitZap(viper.GetInt("verbosity")); err != nil {
		return fmt.Errorf("failed init zap logger in root command: %v", err)
	}

	return nil
}

func Execute() error {
	return rootCmd.ExecuteContext(context.Background())
}
