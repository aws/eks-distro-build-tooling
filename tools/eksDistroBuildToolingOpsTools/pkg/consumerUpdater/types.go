package consumerUpdater

type Consumer interface {
	Info() ConsumerInfo
	UpdateAll() error
	Updaters() []Updater
	NotifyAll() error
	Notifiers() []Notifier
}

type Notifier interface {
	Notify() error
}

type Updater interface {
	Update() error
}

type ConsumerInfo struct {
	Name string
}
