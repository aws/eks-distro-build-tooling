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
	repositoryOwnerFlag = "owner"
	repositoryFlag      = "repository"
	githubEmailFlag     = "githubEmail"
	commitBranch        = "baseBranch"
	authorNameFlag      = "author"
)

var rootCmd = &cobra.Command{
	Use:              "eksGoTool",
	Short:            "Amazon EKS Golang Operational Tooling",
	Long:             `Tools for the release, management and operations of EKS Go`,
	PersistentPreRun: rootPersistentPreRun,
}

func init() {
	rootCmd.PersistentFlags().IntP("verbosity", "v", 0, "Set the log level verbosity")
	rootCmd.PersistentFlags().StringVar(repositoryFlag, "eks-distro-build-tooling", "The name of the repository to operate against")
	rootCmd.PersistentFlags().StringVar(repositoryOwnerFlag, "aws", "Name of the owner of the target GitHub repository")
	rootCmd.PersistentFlags().StringVar(githubEmailFlag, "", "Email associated with the GitHub account")
	rootCmd.PersistentFlags().StringVar(commitBranch, "", "Base branch against which pull requests should be made")
	rootCmd.PersistentFlags().StringVar(authorNameFlag, "", "Author of any commits made by the CLI")
	if err := viper.BindPFlags(rootCmd.PersistentFlags()); err != nil {
		log.Fatalf("failed to binPersistentF flags for root: %v", err)
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
