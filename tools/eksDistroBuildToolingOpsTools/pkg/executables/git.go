package executables

import (
	"context"
	"fmt"
)

// Git is an executable for running Git commands locally not privided by go-git or go-github.
type Git struct {
	Executable
}

const (
	gitPath             = "git"
)

// NewGit returns a new instance of Git client.
func NewGit(executable Executable) *Git {
	return &Git{
		Executable: executable,
	}
}

// Am runs 'git am ' using Git.
func (g *Git) Am(ctx context.Context, , , string, command ...string) (string, error) {
	params := []string{
	}
	params = append(params, command...)

	out, err := g.Executable.Execute(ctx, params...)
	if err != nil {
		return "", fmt.Errorf("running Git command: %v", err)
	}

	return out.String(), nil
}
