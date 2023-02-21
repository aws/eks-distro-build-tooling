package dependencyUpdater

import "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/eksDistroRelease"

func NewFactory(releases []*eksDistroRelease.Release) *Factory {
	var dependencies []Dependency
	dependencies = append(dependencies, NewEtcdDependencyUpdater(releases))

	return &Factory{
		dependencyUpdaters: dependencies,
	}
}

type Factory struct {
	dependencyUpdaters []Dependency
}

func (f Factory) DependencyUpdaters() []Dependency {
	return f.dependencyUpdaters
}
