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

package v1alpha1

// ReleaseStatus defines the observed state of Release
type ReleaseStatus struct {

	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Type=string
	// +kubebuilder:validation:Format=date-time
	Date string `json:"date,omitempty"`

	// +kubebuilder:validation:Required
	Components []Component `json:"components,omitempty"`
}

// A component of a release
type Component struct {
	// +kubebuilder:validation:Required
	Name string `json:"name,omitempty"`

	// +kubebuilder:validation:Required
	// Git commit the component is built from, before any patches
	GitCommit string `json:"gitCommit,omitempty"`
	// Git tag the component is built from, before any patches
	GitTag string `json:"gitTag,omitempty"`

	// +kubebuilder:validation:Required
	Assets []Asset `json:"assets,omitempty"`
}

type Asset struct {
	// +kubebuilder:validation:Required
	// The asset name
	Name string `json:"name,omitempty"`

	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Enum=Archive;Image;
	// The type of the asset
	Type string `json:"type,omitempty"`

	// +kubebuilder:validation:Required
	Description string `json:"description,omitempty"`

	// +kubebuilder:validation:Enum=linux;darwin;windows
	// Operating system of the asset
	OS string `json:"os,omitempty"`

	// Architectures of the asset
	Arch []string `json:"arch,omitempty"`

	// +optional
	Image *AssetImage `json:"image,omitempty"`

	// +optional
	Archive *AssetArchive `json:"archive,omitempty"`
}

type AssetArchive struct {
	// +kubebuilder:validation:Required
	// The path of the server at which the asset is located
	Path string `json:"path,omitempty"`
	// +kubebuilder:validation:Required
	// The sha512 of the asset, only applies for 'file' store
	SHA512 string `json:"sha512,omitempty"`
	// +kubebuilder:validation:Required
	// The sha256 of the asset, only applies for 'file' store
	SHA256 string `json:"sha256,omitempty"`
}
type AssetImage struct {
	// +kubebuilder:validation:Required
	// The image repository, name, and tag
	URI string `json:"uri,omitempty"`
}
