package consumerUpdater

import (
	"fmt"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"
)

const (
	bottlerocketName = "Bottlerocket"
)

func NewBottleRocketUpdater(releases []*eksDistroRelease.Release) *BottlerocketUpdater {
	return &BottlerocketUpdater{
		updaters:         bottlerocketUpdaters(releases),
		notifiers:        bottlerocketNotifiers(),
		bottlerocketInfo: bottlerocketConsumerInfo(),
	}
}

type BottlerocketUpdater struct {
	updaters         []Updater
	notifiers        []Notifier
	bottlerocketInfo ConsumerInfo
}

func (b BottlerocketUpdater) Updaters() []Updater {
	return b.updaters
}

func (b BottlerocketUpdater) Notifiers() []Notifier {
	return b.notifiers
}

func (b BottlerocketUpdater) Info() ConsumerInfo {
	return b.bottlerocketInfo
}

func bottlerocketConsumerInfo() ConsumerInfo {
	return ConsumerInfo{
		Name: bottlerocketName,
	}
}

func bottlerocketUpdaters(releases []*eksDistroRelease.Release) []Updater {
	var updaters []Updater
	updaters = append(updaters, bottlerocketGithubUpdaters(releases)...)
	return updaters
}

func bottlerocketGithubUpdaters(releases []*eksDistroRelease.Release) []Updater {
	var updaters []Updater
	for _, r := range releases {
		updaters = append(updaters, &bottlerocketGithubUpdater {
			eksDistroRelease: r,
		})
	}
	return updaters
}

func bottlerocketNotifiers() []Notifier {
	return []Notifier{}
}

type bottlerocketGithubUpdater struct {
	eksDistroRelease *eksDistroRelease.Release
}

func (g *bottlerocketGithubUpdater) Update() error {
	//implement updater here
	fmt.Printf("Bottlerocket update stub invoked for EKS D release \n Major: %d\n Minor: %d\n Patch: %d\n Release: %d\n",
		g.eksDistroRelease.KubernetesMajorVersion(),
		g.eksDistroRelease.KubernetesMinorVersion(),
		g.eksDistroRelease.KubernetesPatchVersion(),
		g.eksDistroRelease.ReleaseNumber())
	return nil
}