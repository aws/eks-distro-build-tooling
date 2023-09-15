
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease"
)

var (
	backportGoCommand = &cobra.Command{
		Use:   "backport",
		Short: "Update new patch versions of EKS Go",
		Long:  "Tool to create PR for updaing EKS Go versions supported by upstream when a patch version is released",
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
				err := r.BackportPatchVersion(cmd.Context(), viper.GetBool(dryrunFlag), "CVE", "HASH", viper.GetString(emailFlag), viper.GetString(userFlag))
				if err != nil {
					return fmt.Errorf("You have failed this automation: %w", err)
				}
			}
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(backportGoCommand)
}
