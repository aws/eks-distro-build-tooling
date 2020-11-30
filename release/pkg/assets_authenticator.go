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
	"path"

	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
)

// GetKubernetesComponent returns the Component for Kubernetes
func (r *ReleaseConfig) GetAuthenticatorComponent(spec distrov1alpha1.ReleaseSpec) (*distrov1alpha1.Component, error) {
	projectSource := "projects/kubernetes-sigs/aws-iam-authenticator"
	tagFile := path.Join(r.BuildRepoSource, projectSource, "GIT_TAG")
	gitTag, err := readTag(tagFile)
	if err != nil {
		return nil, errors.Cause(err)
	}
	assets := []distrov1alpha1.Asset{}
	osArchMap := map[string][]string{
		"linux":   []string{"arm64", "amd64"},
		"windows": []string{"amd64"},
		"darwin":  []string{"amd64"},
	}
	for os, arches := range osArchMap {
		for _, arch := range arches {
			filename := fmt.Sprintf("aws-iam-authenticator-%s-%s-%s.tar.gz", os, arch, gitTag)
			tarfile := path.Join(r.BuildRepoSource, projectSource, "_output/tar", filename)

			sha256, sha512, err := r.readShaSums(tarfile)
			if err != nil {
				return nil, errors.Cause(err)
			}
			assetPath, err := r.GetURI(path.Join(
				fmt.Sprintf("kubernetes-%s", spec.Channel),
				"releases",
				fmt.Sprintf("%d", spec.Number),
				"artifacts",
				"aws-iam-authenticator",
				gitTag,
				filename,
			))
			if err != nil {
				return nil, errors.Cause(err)
			}
			assets = append(assets, distrov1alpha1.Asset{
				Name:        filename,
				Type:        "Archive",
				Description: fmt.Sprintf("aws-iam-authenticator tarball for %s/%s", os, arch),
				OS:          os,
				Arch:        []string{arch},
				Archive: &distrov1alpha1.AssetArchive{
					URI:    assetPath,
					SHA512: sha512,
					SHA256: sha256,
				},
			})
		}
	}
	binary := "aws-iam-authenticator"
	assets = append(assets, distrov1alpha1.Asset{
		Name:        fmt.Sprintf("%s-image", binary),
		Type:        "Image",
		Description: fmt.Sprintf("%s container image", binary),
		OS:          "linux",
		Arch:        []string{"amd64", "arm64"},
		Image: &distrov1alpha1.AssetImage{
			URI: fmt.Sprintf("%s/kubernetes-sigs/%s:%s-eks-%s-%d",
				r.ContainerImageRepository,
				binary,
				gitTag,
				spec.Channel,
				spec.Number,
			),
		},
	})
	component := &distrov1alpha1.Component{
		Name:   "aws-iam-authenticator",
		GitTag: gitTag,
		Assets: assets,
	}
	return component, nil
}
