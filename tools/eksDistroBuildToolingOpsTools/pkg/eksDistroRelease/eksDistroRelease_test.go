package eksDistroRelease_test

import (
	"testing"

	"github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"
)

func TestIssueManagerCreateIssueSuccess(t *testing.T) {
	releaseObject, err := eksDistroRelease.NewEksDistroReleaseObject("1.25.5-5")
	if err != nil {
		t.Errorf("NewEksDistroReleaseObject error = %v, want nil", err)
	}

	testReleaseObject := newTestEksDistroRelease(t)

	releasesAreEqual := releaseObject.Equals(testReleaseObject)
	if !releasesAreEqual {
		t.Errorf("EKS Distro Release object is not equal to the test Release object! Release object: %v, testReleaseObject: %v", releaseObject, testReleaseObject)
	}
}

func newTestEksDistroRelease(t *testing.T) eksDistroRelease.Release {
	return eksDistroRelease.Release {
		Major:    1,
		Minor:    25,
		Patch:    5,
		Release:  5,
		Manifest: &v1alpha1.Release{},
	}
}
