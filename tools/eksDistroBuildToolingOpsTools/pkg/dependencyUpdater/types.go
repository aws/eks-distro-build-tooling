package dependencyUpdater

type Dependency interface {
	Info() DependencyInfo
	UpdateAll() error
	Updaters() []Updater
}

type Updater interface {
	Update() error
}

type DependencyInfo struct {
	Name string
}
