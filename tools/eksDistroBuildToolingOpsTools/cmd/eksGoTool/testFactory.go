package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	updateConsumerCommand = &cobra.Command{
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

			fmt.Println("EKS Go Released")
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(updateConsumerCommand)
}
