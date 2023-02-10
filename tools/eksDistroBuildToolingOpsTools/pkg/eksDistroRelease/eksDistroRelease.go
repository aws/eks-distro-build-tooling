package eksDistroRelease

import (
	"fmt"
	"strconv"
	"strings"
)

func NewEksDistroReleaseObject(versionString string) (*Release, error) {
	splitVersion := strings.Split(versionString, ".")
	patchAndRelease := strings.Split(splitVersion[2], "-")
	major, err :=  strconv.Atoi(splitVersion[0])
	if err != nil {
		return nil, err
	}

	minor, err :=  strconv.Atoi(splitVersion[1])
	if err != nil {
		return nil, err
	}

	patch, err :=  strconv.Atoi(patchAndRelease[0])
	if err != nil {
		return nil, err
	}

	release, err :=  strconv.Atoi(patchAndRelease[1])
	if err != nil {
		return nil, err
	}

	return &Release{
		major:   major,
		minor:   minor,
		patch:   patch,
		release: release,
	}, nil
}

type Release struct {
	major   int
	minor   int
	patch   int
	release int
}

func (r Release) KubernetesMajorVersion() int {
	return r.major
}

func (r Release) KubernetesMinorVersion() int {
	return r.minor
}

func (r Release) KubernetesPatchVersion() int {
	return r.patch
}

func (r Release) ReleaseNumber() int {
	return r.release
}

func (r Release) EksDistroReleaseFullVersion() string {
	return fmt.Sprintf("v%d.%d.%d-%d", r.major, r.minor, r.patch, r.release)
}

func (r Release) KubernetesFullVersion() string {
	return fmt.Sprintf("v%d.%d.%d", r.major, r.minor, r.patch)
}