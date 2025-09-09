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

package pkg

import (
	"net/url"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecrpublic"
	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
)

// ReleaseConfig contains metadata fields for a release
type ReleaseConfig struct {
	ContainerImageRepository string
	ArtifactURL              string
	BuildRepoSource          string
	ArtifactDir              string
	ReleaseDate              time.Time
}

// GenerateComponentsTable generates a table of EKS-D components
func (r *ReleaseConfig) GenerateComponentsTable(release *distrov1alpha1.Release) (map[string]*distrov1alpha1.Component, error) {
	componentsTable := map[string]*distrov1alpha1.Component{}
	componentFuncs := map[string]func(distrov1alpha1.ReleaseSpec) (*distrov1alpha1.Component, error){
		"kubernetes":            r.GetKubernetesComponent,
		"kube-proxy":            r.GetKubeProxyComponent,
		"aws-iam-authenticator": r.GetAuthenticatorComponent,
		"livenessprobe":         r.GetLivenessprobeComponent,
		"external-attacher":     r.GetAttacherComponent,
		"external-provisioner":  r.GetProvisionerComponent,
		"external-resizer":      r.GetResizerComponent,
		"node-driver-registrar": r.GetRegistrarComponent,
		"external-snapshotter":  r.GetSnapshotterComponent,
		"metrics-server":        r.GetMetricsServerComponent,
		"cni-plugin":            r.GetCniComponent,
		"etcd":                  r.GetEtcdComponent,
		"coredns":               r.GetCorednsComponent,
	}
	for componentName, componentFunc := range componentFuncs {
		component, err := componentFunc(release.Spec)
		if err != nil {
			return nil, errors.Wrapf(err, "Error getting %s components", componentName)
		}
		componentsTable[componentName] = component
	}

	return componentsTable, nil
}

// UpdateReleaseStatus returns a release struct
func (r *ReleaseConfig) UpdateReleaseStatus(release *distrov1alpha1.Release, componentsTable map[string]*distrov1alpha1.Component) error {
	components := []distrov1alpha1.Component{}
	for _, component := range componentsTable {
		components = append(components, *component)
	}

	release.Status = distrov1alpha1.ReleaseStatus{
		Date:       r.ReleaseDate.Format(time.RFC3339),
		Components: components,
	}
	return nil
}

func UpdateImageDigests(ecrPublicClient *ecrpublic.ECRPublic, r *ReleaseConfig, componentsTable map[string]*distrov1alpha1.Component) error {
	for _, component := range componentsTable {
		componentDer := *component
		assets := componentDer.Assets
		for _, asset := range assets {
			if asset.Image != nil {
				// Skip digest updates for external CSI components
				if strings.Contains(asset.Image.URI, "public.ecr.aws/csi-components/") {
					continue
				}
				var imageTag string
				releaseUriSplit := strings.Split(asset.Image.URI, ":")
				repoName := strings.Replace(releaseUriSplit[0], r.ContainerImageRepository+"/", "", -1)
				imageTag = releaseUriSplit[1]
				describeImagesOutput, err := ecrPublicClient.DescribeImages(
					&ecrpublic.DescribeImagesInput{
						ImageIds: []*ecrpublic.ImageIdentifier{
							{
								ImageTag: aws.String(imageTag),
							},
						},
						RepositoryName: aws.String(repoName),
					},
				)
				if err != nil {
					return errors.Cause(err)
				}

				imageDigest := describeImagesOutput.ImageDetails[0].ImageDigest

				asset.Image.ImageDigest = *imageDigest
			}
		}
	}

	return nil
}

// GetURI returns an full URL for the given path
func (r *ReleaseConfig) GetURI(path string) (string, error) {
	uri, err := url.Parse(r.ArtifactURL)
	if err != nil {
		return "", err
	}
	uri.Path = path
	return uri.String(), nil
}
