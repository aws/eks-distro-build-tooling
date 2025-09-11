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
)

// GetKubeProxyComponent returns the Component for kube-proxy
func (r *ReleaseConfig) GetKubeProxyComponent(spec distrov1alpha1.ReleaseSpec) (*distrov1alpha1.Component, error) {
	projectSource := "projects/kubernetes/kubernetes"
	projectGitTagFolder := "kube-proxy"
	tagFile := filepath.Join(r.BuildRepoSource, projectSource, spec.Channel, projectGitTagFolder, "GIT_TAG")
	gitTag, err := readTag(tagFile)
	if err != nil {
		return nil, err
	}

	kubernetesGitTag, err := r.readK8sTag(r.BuildRepoSource, spec.Channel)
	if err != nil {
		return nil, err
	}

	var assets []distrov1alpha1.Asset

	// Binary assets for kube-proxy
	binaryAssets := r.getKubeProxyBinaryAssets(kubernetesGitTag, spec)
	assets = append(assets, binaryAssets...)

	// Image assets for kube-proxy
	imageAssets := r.getKubeProxyImageAssets(gitTag, kubernetesGitTag, spec)
	assets = append(assets, imageAssets...)

	component := &distrov1alpha1.Component{
		Name:   "kube-proxy",
		GitTag: gitTag,
		Assets: assets,
	}

	return component, nil
}

func (r *ReleaseConfig) getKubeProxyBinaryAssets(gitTag string, spec distrov1alpha1.ReleaseSpec) []distrov1alpha1.Asset {
	var assets []distrov1alpha1.Asset

	osArchMap := map[string][]string{
		"linux":   {"arm64", "amd64"},
		"windows": {"amd64"},
	}

	osBinaryMap := map[string]string{
		"linux":   "kube-proxy",
		"windows": "kube-proxy.exe",
	}

	for os, arches := range osArchMap {
		binary := osBinaryMap[os]
		for _, arch := range arches {
			filename := filepath.Join("bin", os, arch, binary)
			sha256, sha512, err := r.ReadK8sShaSums(gitTag, filename)
			if err != nil {
				continue
			}
			assetPath, err := r.GetURI(filepath.Join(
				fmt.Sprintf("kubernetes-%s", spec.Channel),
				"releases",
				fmt.Sprintf("%d", spec.Number),
				"artifacts",
				"kubernetes",
				gitTag,
				filename,
			))
			if err != nil {
				continue
			}
			assets = append(assets, distrov1alpha1.Asset{
				Name:        filename,
				Type:        "Archive",
				Description: fmt.Sprintf("kube-proxy binary for %s/%s", os, arch),
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

	return assets
}

func (r *ReleaseConfig) getKubeProxyImageAssets(gitTag, kubernetesGitTag string, spec distrov1alpha1.ReleaseSpec) []distrov1alpha1.Asset {
	var assets []distrov1alpha1.Asset

	// Container image
	assets = append(assets, distrov1alpha1.Asset{
		Name:        "kube-proxy-image",
		Type:        "Image",
		Description: "kube-proxy container image",
		OS:          "linux",
		Arch:        []string{"amd64", "arm64"},
		Image: &distrov1alpha1.AssetImage{
			URI: fmt.Sprintf("%s/kubernetes/kube-proxy:%s-eks-%s-%d",
				r.ContainerImageRepository,
				gitTag,
				spec.Channel,
				spec.Number,
			),
		},
	})

	// Image tar assets
	linuxImageArches := []string{"amd64", "arm64"}
	for _, arch := range linuxImageArches {
		filename := filepath.Join("bin", "linux", arch, "kube-proxy.tar")
		sha256, sha512, err := r.ReadK8sShaSums(kubernetesGitTag, filename)
		if err != nil {
			continue
		}
		assetPath, err := r.GetURI(filepath.Join(
			fmt.Sprintf("kubernetes-%s", spec.Channel),
			"releases",
			fmt.Sprintf("%d", spec.Number),
			"artifacts",
			"kubernetes",
			kubernetesGitTag,
			filename,
		))
		if err != nil {
			continue
		}
		assets = append(assets, distrov1alpha1.Asset{
			Name:        filename,
			Type:        "Archive",
			Description: fmt.Sprintf("kube-proxy linux/%s OCI image tar", arch),
			OS:          "linux",
			Arch:        []string{arch},
			Archive: &distrov1alpha1.AssetArchive{
				URI:    assetPath,
				SHA512: sha512,
				SHA256: sha256,
			},
		})
	}

	return assets
}
