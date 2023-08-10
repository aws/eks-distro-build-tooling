package projectUpdater

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/aws/eks-distro-build-tooling/tools/pkg/logger"
)

const (
	golangName        = "golang"
	golangGHOrg       = "golang"
	golangGHReop      = "go"
	golangProjectPath = "projects/golang/go/"
	golangVersionPath = "%s/%s/"
	golangPatchesPath = "%s/%s/"
	golangRPMPath     = "%s/%s/"
)

func NewGolangUpdater() Project {
	return &GolangUpdater{
		updaters:   golangUpdaters(),
		golangInfo: golangProjectInfo(),
	}
}

type GolangUpdater struct {
	updaters   []Updater
	golangInfo ProjectInfo
}

func (g GolangUpdater) Updaters() []Updater {
	return g.updaters
}

func (g GolangUpdater) UpdateAll() error {
	for _, u := range g.Updaters() {
		err := u.Update()
		if err != nil {
			return err
		}
	}
	return nil
}

func (g GolangUpdater) Info() ProjectInfo {
	return g.golangInfo
}

func golangProjectInfo() ProjectInfo {
	return ProjectInfo{
		Name: golangName,
		Org:  golangOrg,
		Repo: golangRepo,
		Path: golangProjectPath,
	}
}

func golangUpdaters() []Updater {
	var updaters []Updater
	updaters = append(updaters, golangGithubUpdaters()...)
	return updaters
}

func golangGithubUpdaters() []Updater {
	var updaters []Updater
	for _, r := range releases {
		updaters = append(updaters, &golangGithubUpdater{})
	}
	return updaters
}

type golangGithubUpdater struct {
}

func (g *golangGithubUpdater) Update() error {
	//implement updater here
	fmt.Printf("Golang project update invoked for EKS Go release \n Major: %d\n Minor: %d\n Patch: %d\n Release: %d\n",
		g.GolangMajorVersion(),
		g.GolangMinorVersion(),
		g.GolangPatchVersion(),
		g.ReleaseNumber())
	return nil
}

type Release struct {
	Major   int
	Minor   int
	Patch   int
	Release int
}

func (r Release) GolangReleaseBranch() string {
	return fmt.Sprintf("release-branch.go%d.%d", r.Major, r.Minor)
}

func (r Release) GolangMajorVersion() int {
	return r.Major
}

func (r Release) GolangMinorVersion() int {
	return r.Minor
}

func (r Release) GolangPatchVersion() int {
	return r.Patch
}

func (r Release) ReleaseNumber() int {
	return r.Release
}

func (r Release) EksGolangReleaseFullVersion() string {
	return fmt.Sprintf("v%d.%d.%d-%d", r.Major, r.Minor, r.Patch, r.Release)
}

func (r Release) GolangFullVersion() string {
	return fmt.Sprintf("%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) GolangSemver() string {
	return fmt.Sprintf("v%d.%d.%d", r.Major, r.Minor, r.Patch)
}

func (r Release) Equals(release Release) bool {
	if r.Major != release.GolangMajorVersion() {
		logger.V(4).Info("Major version not equal", "self Major", r.Major, "compare Major", release.GolangMajorVersion())
		return false
	}
	if r.Minor != release.GolangMinorVersion() {
		logger.V(4).Info("Minor version not equal", "self Minor", r.Minor, "compare Minor", release.GolangMinorVersion())
		return false
	}
	if r.Patch != release.GolangPatchVersion() {
		logger.V(4).Info("Patch version not equal", "self Patch", r.Patch, "compare Patch", release.GolangPatchVersion())
		return false
	}
	if r.Release != release.ReleaseNumber() {
		logger.V(4).Info("Release version not equal", "self Release", r.Release, "compare Release", release.ReleaseNumber())
		return false
	}
	return true
}

func golangHomeDir() (string, error) {
	dir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "workspace", "golang"), nil
}
