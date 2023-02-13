package consumerUpdater

import "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"

func NewFactory(releases []*eksDistroRelease.Release) *Factory {
	var consumers []Consumer
	consumers = append(consumers, NewBottleRocketUpdater(releases))

	return &Factory{
		consumerUpdaters: consumers,
	}
}

type Factory struct {
	consumerUpdaters []Consumer
}

func (f Factory) ConsumerUpdaters() []Consumer {
	return f.consumerUpdaters
}
