// Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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
	"path/filepath"

	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
)

// GetAttacherComponent returns the Component for Kubernetes
func (r *ReleaseConfig) GetAttacherComponent(spec distrov1alpha1.ReleaseSpec) (*distrov1alpha1.Component, error) {
	projectSource := "projects/kubernetes-csi/external-attacher"
	tagFile := filepath.Join(r.BuildRepoSource, projectSource, "GIT_TAG")
	gitTag, err := readTag(tagFile)
	if err != nil {
		return nil, errors.Cause(err)
	}
	assets := []distrov1alpha1.Asset{}
	binary := "external-attacher"
	assets = append(assets, distrov1alpha1.Asset{
		Name:        fmt.Sprintf("%s-image", binary),
		Type:        "Image",
		Description: fmt.Sprintf("%s container image", binary),
		OS:          "linux",
		Arch:        []string{"amd64", "arm64"},
		Image: &distrov1alpha1.AssetImage{
			URI: fmt.Sprintf("%s/kubernetes-csi/%s:%s-eks-%s-%d",
				r.ContainerImageRepository,
				binary,
				gitTag,
				spec.Channel,
				spec.Number,
			),
		},
	})
	component := &distrov1alpha1.Component{
		Name:   "external-attacher",
		GitTag: gitTag,
		Assets: assets,
	}
	return component, nil
}
