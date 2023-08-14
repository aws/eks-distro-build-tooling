package cmd

import (
	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease"
)

var (
	updateGoCommand = &cobra.Command{
		Use:   "update",
		Short: "Update existing version(s) of EKS Go",
		Long:  "Tool to update existing version(s) of EKS Go whether they are supported by us or upstream",
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
				r.Update()
			}
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(updateGoCommand)
}
