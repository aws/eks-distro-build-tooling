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
	"fmt"

	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
)

// ReleaseMap mapping from release channel to last release of metrics server for prod (which is basically the same for dev)
var ReleaseMap = map[string]int{
	"1-33": 8,
	"1-32": 8,
	"1-31": 16,
	"1-30": 27,
	"1-29": 34,
	"1-28": 45,
}

// GetMetricsServerComponent returns the Component for Metrics Server
// this is hard coded until EKS-A deprecates their usage of metrics server
func (r *ReleaseConfig) GetMetricsServerComponent(spec distrov1alpha1.ReleaseSpec) (*distrov1alpha1.Component, error) {
	componentName := "metrics-server"
	gitTag := "v0.7.2"

	effectiveChannel := spec.Channel
	if spec.Channel == "1-33" {
		effectiveChannel = "1-32"
	}

	releaseNumber, exists := ReleaseMap[effectiveChannel]
	if !exists {
		return nil, fmt.Errorf("no release number for channel %s", effectiveChannel)
	}

	component := &distrov1alpha1.Component{
		Name:   componentName,
		GitTag: gitTag,
		Assets: []distrov1alpha1.Asset{
			{
				Name:        fmt.Sprintf("%s-image", componentName),
				Type:        "Image",
				Description: fmt.Sprintf("%s container image", componentName),
				OS:          "linux",
				Arch:        []string{"amd64", "arm64"},
				Image: &distrov1alpha1.AssetImage{
					URI: fmt.Sprintf("%s/kubernetes-sigs/%s:%s-eks-%s-%d",
						r.ContainerImageRepository,
						componentName,
						gitTag,
						effectiveChannel,
						releaseNumber,
					),
				},
			},
		},
	}
	return component, nil
}

