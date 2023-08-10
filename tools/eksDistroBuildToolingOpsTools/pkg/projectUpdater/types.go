package projectUpdater

type Project interface {
	Info() ProjectInfo
	UpdateAll() error
	Updaters() []Updater
}

type Updater interface {
	Update() error
}

type ProjectInfo struct {
	Name string
	Org  string
	Repo string
	Path string
}
