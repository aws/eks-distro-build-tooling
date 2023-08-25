package cmd

import (
	"context"
	"fmt"
	"log"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

const (
	repositoryOwnerFlag = "owner"
	repositoryFlag      = "repository"
	githubEmailFlag     = "githubEmail"
	commitBranchFlag    = "baseBranch"
	authorNameFlag      = "author"
	dryrunFlag          = "dryrun"
)

var (
	config string // config file location

	rootCmd = &cobra.Command{
		Use:              "eksGoTool",
		Short:            "Amazon EKS Golang Operational Tooling",
		Long:             `Tools for the release, management and operations of EKS Go`,
		PersistentPreRun: rootPersistentPreRun,
	}
)

func init() {
	// Config defaults
	repository := "eks-distro-build-tooling"
	owner := "aws"
	githubEmail := ""
	commitBranch := ""
	authorName := ""

	// Config flags
	rootCmd.PersistentFlags().IntP("verbosity", "v", 0, "Set the log level verbosity")
	rootCmd.PersistentFlags().String(repositoryFlag, repository, "The name of the repository to operate against")
	rootCmd.PersistentFlags().String(repositoryOwnerFlag, owner, "Name of the owner of the target GitHub repository")
	rootCmd.PersistentFlags().String(githubEmailFlag, githubEmail, "Email associated with the GitHub account")
	rootCmd.PersistentFlags().String(commitBranchFlag, commitBranch, "Base branch against which pull requests should be made")
	rootCmd.PersistentFlags().String(authorNameFlag, authorName, "Author of any commits made by the CLI")

	// Bind config flags to viper
	if err := viper.BindPFlags(rootCmd.PersistentFlags()); err != nil {
		log.Fatalf("failed to bind persistent flags for root: %v", err)
	}

	// Cli flags
	rootCmd.Flags().StringVar(&config, "config", "", "Path to config file with extension")
}

func rootPersistentPreRun(cmd *cobra.Command, args []string) {
	if err := readConfig(); err != nil {
		log.Fatal(err)
	}
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

func readConfig() error {
	// Attempt to parse the config file when flag present
	if config != "" {
		filename := filepath.Base(config)
		viper.SetConfigName(strings.TrimSuffix(filename, filepath.Ext(filename)))
		viper.AddConfigPath(filepath.Dir(config))

		if err := viper.ReadInConfig(); err != nil {
			return fmt.Errorf("read config into viper: %v", err)
		}
	}
	return nil
}

func Execute() error {
	return rootCmd.ExecuteContext(context.Background())
}
