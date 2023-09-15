package git

import (
	"context"
)

type Client interface {
	Add(filename string) error
	Remove(filename string) error
	Clone(ctx context.Context) error
	Commit(message string, opts ...CommitOpt) error
	Push(ctx context.Context) error
	Pull(ctx context.Context, branch string) error
	Status() error
	Init() error
	Branch(name string) error
	ValidateRemoteExists(ctx context.Context) error
	// filename for all the functions should be the full path from the repo base
	// ie "project/golang/go/1.21/README.md
	CreateFile(filename string, contents []byte) error
	CopyFile(curFile, dstFile string) error
	MoveFile(curFile, dstFile string) error
	DeleteFile(filename string) error
	ModifyFile(filename string, contents []byte) error
	ReadFile(filename string) (string, error)
	ReadFiles(foldername string) (map[string]string, error)
}
