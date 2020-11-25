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

package v1alpha1

// ReleaseChannelStatus defines the observed state of ReleaseChannel
type ReleaseChannelStatus struct {
	// +kubebuilder:validation:Required
	Active bool `json:"active,omitempty"`
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=1
	LatestRelease int `json:"latestRelease,omitempty"`
}
