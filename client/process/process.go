package process

import (
	"context"
	"errors"
	"flag"
	"os"
	"os/exec"
)

var ErrNoCommand = errors.New("no command provided")

type Process struct {
	cmd *exec.Cmd
}

func RunFromArgs(ctx context.Context) (*Process, error) {
	flag.Parse()
	args := flag.Args()

	var cmdArgs []string
	if len(args) == 0 {
		return nil, ErrNoCommand
	}
	if len(args) > 1 {
		cmdArgs = args[1:]
	}

	p, err := run(ctx, args[0], cmdArgs...)
	if err != nil {
		return nil, err
	}

	return p, nil
}

func run(ctx context.Context, cmd string, args ...string) (*Process, error) {
	p := &Process{
		cmd: exec.CommandContext(ctx, cmd, args...),
	}

	p.cmd.Stdin = os.Stdin
	p.cmd.Stdout = os.Stdout
	p.cmd.Stderr = os.Stderr

	if err := p.cmd.Run(); err != nil {
		return nil, err
	}

	return p, nil
}

func (p *Process) Cancel() error {
	return p.cmd.Cancel()
}
