package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease"
)

var (
	releaseGoCommand = &cobra.Command{
		Use:   "release",
		Short: "Release a new version of EKS Go",
		Long:  "Tool to release new versions of EKS Go",
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
				err := r.NewMinorRelease(cmd.Context())
				if err != nil {
					return fmt.Errorf("You have failed this automation: %w", err)
				}
			}
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(releaseGoCommand)
}
