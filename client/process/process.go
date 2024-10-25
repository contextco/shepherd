package process

import (
	"context"
	"errors"
	"flag"
	"io"
	"onprem/circular"
	"os"
	"os/exec"
	"time"
)

var ErrNoCommand = errors.New("no command provided")

var flagSet = flag.NewFlagSet(os.Args[0], flag.ExitOnError)

type Process struct {
	cmd       *exec.Cmd
	startedAt time.Time

	stdout *circular.Buffer
	stderr *circular.Buffer
}

func NewFromArgs(ctx context.Context) (*Process, error) {
	ensureFlagsParsed()

	args := flagSet.Args()

	var cmdArgs []string
	if len(args) == 0 {
		return nil, ErrNoCommand
	}
	if len(args) > 1 {
		cmdArgs = args[1:]
	}

	return &Process{
		cmd: exec.CommandContext(ctx, args[0], cmdArgs...),
	}, nil
}

func RunFromArgs(ctx context.Context) (*Process, error) {
	p, err := NewFromArgs(ctx)
	if err != nil {
		return nil, err
	}

	if err := p.Run(ctx); err != nil {
		return nil, err
	}

	return p, nil
}

func New(ctx context.Context, cmd string, args ...string) *Process {
	return &Process{
		cmd: exec.CommandContext(ctx, cmd, args...),
	}
}

func (p *Process) Args() []string {
	return p.cmd.Args
}

func (p *Process) StartedAt() time.Time {
	return p.startedAt
}

func GlobalArgs() []string {
	ensureFlagsParsed()
	return flag.Args()
}

func (p *Process) Run(ctx context.Context) error {
	p.connectPipes()

	if err := p.cmd.Start(); err != nil {
		return err
	}

	p.startedAt = time.Now()
	return nil
}

func (p *Process) RecentLogs(n int) []circular.Line {
	if p.stdout == nil {
		return []circular.Line{}
	}
	return p.stdout.Lines(n)
}

func (p *Process) connectPipes() {
	// TODO: Do something intelligent with collecting this.
	p.cmd.Stdin = os.Stdin

	p.stdout = circular.NewBuffer(1024)
	p.cmd.Stdout = io.MultiWriter(os.Stdout, p.stdout)

	p.stderr = circular.NewBuffer(1024)
	p.cmd.Stderr = io.MultiWriter(os.Stderr, p.stderr)
}

func (p *Process) Cancel() error {
	return p.cmd.Cancel()
}

func ensureFlagsParsed() {
	if flag.Parsed() {
		return
	}
	flagSet.Parse(os.Args[1:])
}
