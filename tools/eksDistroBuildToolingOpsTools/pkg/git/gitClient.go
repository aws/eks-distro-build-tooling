package git

import (
	"context"

	gogit "github.com/go-git/go-git/v5"
)

type Client interface {
	Add(filename string) error
	Remove(filename string) error
	Clone(ctx context.Context) error
	Commit(message string, opts ...CommitOpt) error
	Push(ctx context.Context) error
	Pull(ctx context.Context, branch string) error
	Init() error
	OpenRepo() (*gogit.Repository, error)
	Branch(name string) error
	ValidateRemoteExists(ctx context.Context) error
}
