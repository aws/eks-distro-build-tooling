package executables

import (
	"bytes"
	"context"
)

type commandRunner interface {
	Run(cmd *Command) (stdout bytes.Buffer, err error)
}

type Command struct {
	args          []string
	commandRunner commandRunner
	ctx           context.Context
	envVars       map[string]string
	stdIn         []byte
}

func NewCommand(ctx context.Context, commandRunner commandRunner, args ...string) *Command {
	return &Command{
		commandRunner: commandRunner,
		ctx:           ctx,
		args:          args,
	}
}

func (c *Command) WithEnvVars(envVars map[string]string) *Command {
	c.envVars = envVars
	return c
}

func (c *Command) WithStdIn(stdIn []byte) *Command {
	c.stdIn = stdIn
	return c
}

func (c *Command) Run() (out bytes.Buffer, err error) {
	return c.commandRunner.Run(c)
}
