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
	"sigs.k8s.io/yaml"
	"time"

	"github.com/aws/aws-sdk-go/service/ecrpublic"
	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/aws/eks-distro-build-tooling/release/pkg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// releaseCmd represents the release command
var releaseCmd = &cobra.Command{
	Use:   "release",
	Short: "Cut a eks-distro release",
	PreRun: func(cmd *cobra.Command, args []string) {
		viper.BindPFlags(cmd.Flags())
	},
	Run: func(cmd *cobra.Command, args []string) {
		// TODO validation on these flags
		releaseBranch := viper.GetString("release-branch")
		sourceDir := viper.GetString("source")
		gitCommit := viper.GetString("git-commit")
		imageRepository := viper.GetString("image-repository")
		cdnURL := viper.GetString("cdn")
		releaseNumber := viper.GetInt("release-number")
		devRelease := viper.GetBool("dev-release")
		artifactDir := fmt.Sprintf("kubernetes-%s/releases/%d/artifacts/", releaseBranch, releaseNumber)

		var ecrPublicClient *ecrpublic.ECRPublic
		releaseConfig := &pkg.ReleaseConfig{
			ContainerImageRepository: imageRepository,
			BuildRepoSource:          sourceDir,
			ArtifactDir:              artifactDir,
			ReleaseDate:              time.Now().UTC(),
		}
		release := &distrov1alpha1.Release{
			Spec: distrov1alpha1.ReleaseSpec{
				Channel:         releaseBranch,
				Number:          releaseNumber,
				BuildRepoCommit: gitCommit,
			},
		}
		release.Name = fmt.Sprintf("kubernetes-%s-eks-%d", releaseBranch, releaseNumber)
		// TODO figure out how to get these automatically added
		release.APIVersion = "distro.eks.amazonaws.com/v1alpha1"
		release.Kind = "Release"
		if devRelease {
			client, err := releaseConfig.CreateDevReleaseClients()
			if err != nil {
				fmt.Printf("Error creating clients: %v\n", err)
				os.Exit(1)
			}
			ecrPublicClient = client
			cdnURL, err = buildDevS3URL()
			if err != nil {
				fmt.Printf("Error building dev s3 url: %v\n", err)
				os.Exit(1)
			}
		} else {
			client, err := releaseConfig.CreateProdReleaseClients()
			if err != nil {
				fmt.Printf("Error creating clients: %v\n", err)
				os.Exit(1)
			}
			ecrPublicClient = client
		}
		releaseConfig.ArtifactURL = cdnURL

		componentsTable, err := releaseConfig.GenerateComponentsTable(release)
		if err != nil {
			fmt.Printf("Error generating components table: %+v\n", err)
			os.Exit(1)
		}

		err = pkg.UpdateImageDigests(ecrPublicClient, releaseConfig, componentsTable)
		if err != nil {
			fmt.Printf("Error updating image digests: %+v\n", err)
			os.Exit(1)
		}

		err = releaseConfig.UpdateReleaseStatus(release, componentsTable)
		if err != nil {
			fmt.Printf("Error creating release: %+v\n", err)
			os.Exit(1)
		}

		output, err := yaml.Marshal(release)
		if err != nil {
			fmt.Printf("Error marshaling release: %+v\n", err)
			os.Exit(1)
		}
		fmt.Println(string(output))
	},
}

func buildDevS3URL() (string, error) {
	bucket := os.Getenv("ARTIFACT_BUCKET")
	if bucket == "" {
		return "", fmt.Errorf("ARTIFACT_BUCKET must be set")
	}
	region := "us-west-2" // dev buckets stored in this region
	return fmt.Sprintf("https://%v.s3.%v.amazonaws.com", bucket, region), nil
}

func init() {
	rootCmd.AddCommand(releaseCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// releaseCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	releaseCmd.Flags().String("release-branch", "1-18", "The release branch to create a release for")
	releaseCmd.Flags().String("source", "", "The eks-distro source location")

	// TODO: exec `git -C $SOURCE describe --always --long --abbrev=64 HEAD` instead of prompting
	releaseCmd.Flags().String("git-commit", "", "The eks-distro git commit")
	releaseCmd.Flags().String("image-repository", "", "The container image repository name")
	releaseCmd.Flags().String("cdn", "https://distro.eks.amazonaws.com", "The URL base for artifacts")
	releaseCmd.Flags().Int("release-number", 1, "The release-number to create")
	releaseCmd.Flags().Bool("dev-release", true, "Flag to indicate it's a dev release")
}
