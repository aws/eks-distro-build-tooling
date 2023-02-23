package git

import "context"

type Client interface {
	Add(filename string) error
	Remove(filename string) error
	Clone(ctx context.Context) error
	Commit(message string) error
	Push(ctx context.Context) error
	Pull(ctx context.Context, branch string) error
	Init() error
	Branch(name string) error
	ValidateRemoteExists(ctx context.Context) error
}
