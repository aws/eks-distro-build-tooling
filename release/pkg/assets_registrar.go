/*
Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"). You may
not use this file except in compliance with the License. A copy of the
License is located at

    http://aws.amazon.com/apache2.0/

or in the "license" file accompanying this file. This file is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
express or implied. See the License for the specific language governing
permissions and limitations under the License.
*/
package pkg

import (
	"fmt"
	"path"

	eksDistrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
)

// GetRegistrarComponent returns the Component for Kubernetes
func (r *ReleaseConfig) GetRegistrarComponent(spec eksDistrov1alpha1.ReleaseSpec) (*eksDistrov1alpha1.Component, error) {
	projectSource := "projects/kubernetes-csi/node-driver-registrar"
	tagFile := path.Join(r.BuildRepoSource, projectSource, "GIT_TAG")
	gitTag, err := readTag(tagFile)
	if err != nil {
		return nil, errors.Cause(err)
	}
	assets := []eksDistrov1alpha1.Asset{}
	binary := "node-driver-registrar"
	assets = append(assets, eksDistrov1alpha1.Asset{
		Name:        fmt.Sprintf("%s-image", binary),
		Type:        "Image",
		Description: fmt.Sprintf("%s container image", binary),
		OS:          "linux",
		Arch:        []string{"amd64", "arm64"},
		Image: &eksDistrov1alpha1.AssetImage{
			URI: fmt.Sprintf("%s/kubernetes-csi/%s:%s-eks-%s-%d",
				r.ContainerImageRepository,
				binary,
				gitTag,
				spec.Channel,
				spec.Number,
			),
		},
	})
	component := &eksDistrov1alpha1.Component{
		Name:   "node-driver-registrar",
		GitTag: gitTag,
		Assets: assets,
	}
	return component, nil
}
