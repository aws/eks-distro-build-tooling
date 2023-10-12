package eksGoRelease

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
)

func NewEksGoReleaseObject(versionString string) (*Release, error) {
	splitVersion := strings.Split(versionString, ".")
	major, err := strconv.Atoi(splitVersion[0])
	if err != nil {
		return nil, fmt.Errorf("parsing major version: %v", err)
	}

	minor, err := strconv.Atoi(splitVersion[1])
	if err != nil {
		return nil, fmt.Errorf("parsing minor version: %v", err)
	}

	patch, err := strconv.Atoi(splitVersion[2])
	if err != nil {
		return nil, fmt.Errorf("parsing patch version: %v", err)
	}

	return &Release{
		Major: major,
		Minor: minor,
		Patch: patch,
	}, nil
}

type Release struct {
	Major   int
	Minor   int
	Patch   int
	Release int
}

func (r Release) GoReleaseBranch() string {
	return fmt.Sprintf("release-branch.go%d.%d", r.Major, r.Minor)
}

func (r Release) MajorVersion() int {
	return r.Major
}

func (r Release) MinorVersion() int {
	return r.Minor
}

func (r Release) PatchVersion() int {
	return r.Patch
}

func (r Release) ReleaseNumber() int {
	return r.Release
}

// "https://distro.eks.amazonaws.com/golang-go%d.%d.%d/release/%d/%s/%s/%s"
func (r Release) EksGoArtifacts(arch string) (string, string, string) {
	var artifact string // artifact = "golang-%d.%d.%d-%d.amzn2.eks.%s.rpm"
	var urlFmt string   // artifact = "golang-%d.%d.%d-%d.amzn2.eks.%s.rpm"

	switch arch {
	case "x86_64", "aarch64":
		artifact = fmt.Sprintf(constants.EksGoRpmArtifactFmt, r.Major, r.Minor, r.Patch, r.Release, arch)
		urlFmt = fmt.Sprintf(constants.EksGoArtifactUrl, r.Major, r.Minor, r.Patch, r.Release, arch, "RPMS", arch)
	case "noarch":
		artifact = fmt.Sprintf(constants.EksGoRpmArtifactFmt, r.MajorVersion(), r.MinorVersion(), r.PatchVersion(), r.ReleaseNumber(), arch)
		urlFmt = fmt.Sprintf(constants.EksGoArtifactUrl, r.Major, r.Minor, r.Patch, r.Release, "x86_64", "RPMS", arch)
	case "amd64", "arm64":
		artifact = fmt.Sprintf(constants.EksGoTargzArtifactFmt, r.Major, r.Minor, r.Patch, arch)
		urlFmt = fmt.Sprintf(constants.EksGoArtifactUrl, r.Major, r.Minor, r.Patch, r.Release, "archives", "linux", arch)
	}

	return artifact, fmt.Sprintf("%s.sha256", artifact), urlFmt
}

func (r Release) EksGoAmdBuild() string {
	return fmt.Sprintf(constants.EksGoAmdBuildUrl, r.Major, r.Minor)
}

func (r Release) EksGoArmBuild() string {
	return fmt.Sprintf(constants.EksGoArmBuildUrl, r.Major, r.Minor)
}

func (r Release) EksGoReleaseVersion() string {
	return fmt.Sprintf("v%d.%d.%d-%d", r.Major, r.Minor, r.Patch, r.Release)
}

func (r Release) GoFullVersion() string {
	return fmt.Sprintf("%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) GoMinorVersion() string {
	return fmt.Sprintf("%d.%d", r.Major, r.Minor)
}

func (r Release) GoSemver() string {
	return fmt.Sprintf("v%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) Equals(release Release) bool {
	if r.Major != release.MajorVersion() {
		logger.V(4).Info("Major version not equal", "self Major", r.Major, "compare Major", release.MajorVersion())
		return false
	}
	if r.Minor != release.MinorVersion() {
		logger.V(4).Info("Minor version not equal", "self Minor", r.Minor, "compare Minor", release.MinorVersion())
		return false
	}
	if r.Patch != release.PatchVersion() {
		logger.V(4).Info("Patch version not equal", "self Patch", r.Patch, "compare Patch", release.PatchVersion())
		return false
	}
	if r.Release != release.ReleaseNumber() {
		logger.V(4).Info("Release version not equal", "self Release", r.Release, "compare Release", release.ReleaseNumber())
		return false
	}
	return true
}
