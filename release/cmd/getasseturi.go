// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"fmt"
	"os"

	"github.com/aws/eks-distro-build-tooling/release/pkg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const (
	releaseManifestUrlFlagName = "release-manifest-url"
	releaseBranchFlagName      = "release-branch"
	releaseNumberFlagName      = "release-number"
	componentFlagName          = "component"
	osFlagName                 = "os"
	architectureFlagName       = "arch"
	typeFlagName               = "type"
)

var requiredFlags = []string{componentFlagName, typeFlagName}

// getAssetUriCmd represents the get-asset-uri command

var getAssetUriCmd = &cobra.Command{
	Use:   "get-asset-uri",
	Short: "Get asset URI corresponding to an eks-distro release",
	PreRun: func(cmd *cobra.Command, args []string) {
		viper.BindPFlags(cmd.Flags())
	},
	SilenceUsage: true,
	Run: func(cmd *cobra.Command, args []string) {
		releaseManifestUrl := viper.GetString(releaseManifestUrlFlagName)
		releaseBranch := viper.GetString(releaseBranchFlagName)
		releaseNumber := viper.GetString(releaseNumberFlagName)
		component := viper.GetString(componentFlagName)
		assetType := viper.GetString(typeFlagName)
		osName := viper.GetString(osFlagName)
		arch := viper.GetString(architectureFlagName)

		if releaseManifestUrl == "" && (releaseBranch == "" || releaseNumber == "") {
			fmt.Printf("Both release branch and release number must be provided\n")
			os.Exit(1)
		}

		if releaseManifestUrl != "" && (releaseBranch != "" || releaseNumber != "") {
			fmt.Printf("Both release manifest URL and release branch/number combination cannot be provided\n")
			os.Exit(1)
		}

		if releaseManifestUrl == "" {
			releaseManifestUrl = pkg.GetEksDistroReleaseManifestUrl(releaseBranch, releaseNumber)
		} else {
			releaseBranch, releaseNumber = pkg.ParseEksDistroReleaseManifestUrl(releaseManifestUrl)
		}

		uri, err := pkg.GetAssetUri(releaseManifestUrl, component, assetType, osName, arch)
		if err != nil {
			fmt.Printf("Error getting %s-%s %s asset for component %s in EKS Distro %s-%s release: %v\n", osName, arch, assetType, component, releaseBranch, releaseNumber, err)
			os.Exit(1)
		}

		fmt.Println(uri)
	},
}

func init() {
	rootCmd.AddCommand(getAssetUriCmd)
	getAssetUriCmd.Flags().StringP(releaseManifestUrlFlagName, "f", "", "The release manifest to parse")
	getAssetUriCmd.Flags().StringP(releaseBranchFlagName, "b", "", "The release branch to get assets for")
	getAssetUriCmd.Flags().StringP(releaseNumberFlagName, "n", "", "The release number to get assets for")
	getAssetUriCmd.Flags().StringP(componentFlagName, "c", "", "The component to get URI for")
	getAssetUriCmd.Flags().StringP(typeFlagName, "t", "", "The type of asset for getting URI")
	getAssetUriCmd.Flags().StringP(osFlagName, "o", "linux", "OS of the asset (default: linux)")
	getAssetUriCmd.Flags().StringP(architectureFlagName, "a", "amd64", "Architecture of the asset (default: amd64)")

	for _, flag := range requiredFlags {
		err := getAssetUriCmd.MarkFlagRequired(flag)
		if err != nil {
			fmt.Printf("Error marking flag %s as required: %v", flag, err)
		}
	}
}
