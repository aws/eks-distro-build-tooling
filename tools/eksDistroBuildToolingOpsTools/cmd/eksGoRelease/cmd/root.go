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
	eksGoReleasesFlag = "eksGoReleases"
)

var (
	rootCmd = &cobra.Command{
		Use:              "eksGoRelease",
		Short:            "Amazon EKS Go Release and automation commands",
		Long:             `Tools for updating and releasing EKS Go`,
		PersistentPreRun: rootPersistentPreRun,
	}
)

func init() {
	rootCmd.PersistentFlags().IntP("verbosity", "v", 0, "Set the log level verbosity")
	rootCmd.PersistentFlags().StringSlice(eksGoReleasesFlag, []string{}, "EKS Go releases to update")

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
