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
	"time"

	eksDistrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
)

// ReleaseConfig contains metadata fields for a release
type ReleaseConfig struct {
	ContainerImageRepository string
	BuildRepoSource          string
	ReleaseDate              time.Time
}

// UpdateReleaseStatus returns a release struct
func (r *ReleaseConfig) UpdateReleaseStatus(release *eksDistrov1alpha1.Release) error {
	components := []eksDistrov1alpha1.Component{}
	componentFuncs := map[string]func(eksDistrov1alpha1.ReleaseSpec) (*eksDistrov1alpha1.Component, error){
		"kubernetes":            r.GetKubernetesComponent,
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
			return errors.Wrapf(err, "Error getting %s components", componentName)
		}
		components = append(components, *component)
	}

	release.Status = eksDistrov1alpha1.ReleaseStatus{
		Date:       r.ReleaseDate.Format(time.RFC3339),
		Components: components,
	}
	return nil
}
