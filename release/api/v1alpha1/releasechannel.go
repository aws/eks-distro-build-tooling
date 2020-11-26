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

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ReleaseChannelSpec defines the desired state of ReleaseChannel
type ReleaseChannelSpec struct {
	// +kubebuilder:validation:Required
	SNSTopicARN string `json:"snsTopicARN,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:printcolumn:name="TopicARN",type=string,JSONPath=`.spec.snsTopicARN`,description="The SNS Topic ARN for this release channel"
// +kubebuilder:printcolumn:name="Active",type=bool,JSONPath=`.spec.active`,description="Indicates if this channel is active"
// +kubebuilder:printcolumn:name="Latest Release",type=integer,format=int32,JSONPath=`.spec.latestRelease`,description="The latest release of this channel"
// +kubebuilder:resource:singular="releasechannel",path="releasechannels"

// ReleaseChannel is the Schema for the releasechannels API
type ReleaseChannel struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ReleaseChannelSpec   `json:"spec,omitempty"`
	Status ReleaseChannelStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// ReleaseChannelList contains a list of ReleaseChannel
type ReleaseChannelList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []ReleaseChannel `json:"items"`
}

func init() {
	SchemeBuilder.Register(&ReleaseChannel{}, &ReleaseChannelList{})
}
