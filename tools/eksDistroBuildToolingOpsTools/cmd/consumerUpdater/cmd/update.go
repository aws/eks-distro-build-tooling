package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/consumerUpdater"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"
)

var (
	updateConsumerCommand = &cobra.Command{
		Use:   "update",
		Short: "Update consumers of EKS Distro",
		Long:  "Tool for updating consumers of EKS Distro generated artifacts",
		RunE: func(cmd *cobra.Command, args []string) error {

			var eksDReleases []*eksDistroRelease.Release
			for _, v := range viper.GetStringSlice(eksDistroReleasesFlag) {
				r, err := eksDistroRelease.NewEksDistroReleaseObject(v)
				if err != nil {
					return err
				}
				eksDReleases = append(eksDReleases, r)
			}

			consumerFactory := consumerUpdater.NewFactory(eksDReleases)

			var err error
			for _, c := range consumerFactory.ConsumerUpdaters() {
				err = c.UpdateAll()
				if err != nil {
					return fmt.Errorf("updating consumer %s: %v", c.Info().Name, err)
				}
			}
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(updateConsumerCommand)
}
