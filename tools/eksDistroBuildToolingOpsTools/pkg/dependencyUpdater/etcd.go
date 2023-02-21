package dependencyUpdater

import (
	"fmt"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"
)

const (
	etcdName = "etcd"
)

func NewEtcdDependencyUpdater(releases []*eksDistroRelease.Release) Dependency {
	return &EtcdUpdater{
		updaters: etcdUpdaters(releases),
		etcdInfo: etcdConsumerInfo(),
	}
}

type EtcdUpdater struct {
	updaters  []Updater
	etcdInfo  DependencyInfo
}

func (b EtcdUpdater) Updaters() []Updater {
	return b.updaters
}

func (b EtcdUpdater) UpdateAll() error {
	for _, u := range b.Updaters() {
		err := u.Update()
		if err != nil {
			return err
		}
	}
	return nil
}

func (b EtcdUpdater) Info() DependencyInfo {
	return b.etcdInfo
}

func etcdConsumerInfo() DependencyInfo {
	return DependencyInfo{
		Name: etcdName,
	}
}

func etcdUpdaters(releases []*eksDistroRelease.Release) []Updater {
	var updaters []Updater
	updaters = append(updaters, etcdGithubUpdaters(releases)...)
	return updaters
}

func etcdGithubUpdaters(releases []*eksDistroRelease.Release) []Updater {
	var updaters []Updater
	for _, r := range releases {
		updaters = append(updaters, &etcdGithubUpdater {
			eksDistroRelease: r,
		})
	}
	return updaters
}

type etcdGithubUpdater struct {
	eksDistroRelease *eksDistroRelease.Release
}

func (g *etcdGithubUpdater) Update() error {
	//implement updater here
	fmt.Printf("Etcd dependency update stub invoked for EKS D release \n Major: %d\n Minor: %d\n Patch: %d\n Release: %d\n",
		g.eksDistroRelease.KubernetesMajorVersion(),
		g.eksDistroRelease.KubernetesMinorVersion(),
		g.eksDistroRelease.KubernetesPatchVersion(),
		g.eksDistroRelease.ReleaseNumber())
	return nil
}