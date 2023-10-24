package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease"
)

var releaseCmd = &cobra.Command{
	Use:   "release",
	Short: "Release EKS Go",
	Long:  "Tool to create PRs for releasing EKS Go versions",
	RunE: func(cmd *cobra.Command, args []string) error {
		var eksGoReleases []*eksGoRelease.Release
		for _, v := range viper.GetStringSlice(eksGoReleasesFlag) {
			r, err := eksGoRelease.NewEksGoReleaseObject(v)
			if err != nil {
				return err
			}
			eksGoReleases = append(eksGoReleases, r)
		}

		for _, r := range eksGoReleases {
			err := eksGoRelease.ReleaseArtifacts(cmd.Context(), r, viper.GetBool(dryrunFlag), viper.GetString(emailFlag), viper.GetString(userFlag))
			if err != nil {
				return fmt.Errorf("you have failed this automation: %w", err)
			}
		}
		return nil
	},
}

func init() {
	rootCmd.AddCommand(releaseCmd)
}
