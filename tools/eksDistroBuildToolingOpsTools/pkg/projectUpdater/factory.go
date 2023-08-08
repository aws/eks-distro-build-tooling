package projectUpdater

func NewFactory() *Factory {
	var projects []Project
	projects = append(projects, NewEtcdProjectUpdater(releases))

	return &Factory{
		projectUpdaters: projects,
	}
}

type Factory struct {
	projectUpdaters []Project
}

func (f Factory) ProjectUpdaters() []Project {
	return f.projectUpdaters
}
