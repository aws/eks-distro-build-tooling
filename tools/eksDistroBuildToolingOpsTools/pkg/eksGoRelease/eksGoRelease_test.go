package eksGoRelease_test

import (
	"testing"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease"
)

func TestIssueManagerCreateIssueSuccess(t *testing.T) {
	releaseObject, err := eksGoRelease.NewEksGoReleaseObject("1.25.5")
	if err != nil {
		t.Errorf("NewEksGoReleaseObject error = %v, want nil", err)
	}

	testReleaseObject := newTestEksGoRelease(t)

	releasesAreEqual := releaseObject.Equals(testReleaseObject)
	if !releasesAreEqual {
		t.Errorf("EKS Go Release object is not equal to the test Release object! Release object: %v, testReleaseObject: %v", releaseObject, testReleaseObject)
	}
}

func newTestEksGoRelease(t *testing.T) eksGoRelease.Release {
	//TODO: Update the release value from -1 once we validate needing it and move to a better test value or remove.
	return eksGoRelease.Release{
		Major:   1,
		Minor:   25,
		Patch:   5,
		Release: 0,
	}
}
