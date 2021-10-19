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
	"path/filepath"

	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
)

// GetEtcdComponent returns the Component for Etcd
func (r *ReleaseConfig) GetEtcdComponent(spec distrov1alpha1.ReleaseSpec) (*distrov1alpha1.Component, error) {
	projectSource := "projects/etcd-io/etcd"
	tagFile := filepath.Join(r.BuildRepoSource, projectSource, spec.Channel, "GIT_TAG")
	gitTag, err := readTag(tagFile)
	if err != nil {
		return nil, errors.Cause(err)
	}
	assets := []distrov1alpha1.Asset{}
	osArchMap := map[string][]string{
		"linux": []string{"arm64", "amd64"},
	}
	for os, arches := range osArchMap {
		for _, arch := range arches {
			filename := fmt.Sprintf("etcd-%s-%s-%s.tar.gz", os, arch, gitTag)
			tarfile := filepath.Join(r.ArtifactDir, "etcd", gitTag, filename)

			sha256, sha512, err := r.readShaSums(tarfile)
			if err != nil {
				return nil, errors.Cause(err)
			}
			assetPath, err := r.GetURI(filepath.Join(
				fmt.Sprintf("kubernetes-%s", spec.Channel),
				"releases",
				fmt.Sprintf("%d", spec.Number),
				"artifacts",
				"etcd",
				gitTag,
				filename,
			))
			if err != nil {
				return nil, errors.Cause(err)
			}
			assets = append(assets, distrov1alpha1.Asset{
				Name:        filename,
				Type:        "Archive",
				Description: fmt.Sprintf("etcd tarball for %s/%s", os, arch),
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
	binary := "etcd"
	assets = append(assets, distrov1alpha1.Asset{
		Name:        fmt.Sprintf("%s-image", binary),
		Type:        "Image",
		Description: fmt.Sprintf("%s container image", binary),
		OS:          "linux",
		Arch:        []string{"amd64", "arm64"},
		Image: &distrov1alpha1.AssetImage{
			URI: fmt.Sprintf("%s/etcd-io/%s:%s-eks-%s-%d",
				r.ContainerImageRepository,
				binary,
				gitTag,
				spec.Channel,
				spec.Number,
			),
		},
	})
	component := &distrov1alpha1.Component{
		Name:   "etcd",
		GitTag: gitTag,
		Assets: assets,
	}
	return component, nil
}
