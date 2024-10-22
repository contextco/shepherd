package main

import (
	"context"
	"log"

	"onprem/config"
	"onprem/control"
	"onprem/process"
	"onprem/ssh"

	"github.com/google/uuid"
	"golang.org/x/sync/errgroup"
)

var (
	tsKey = config.Define(
		"ts-key",
		"",
		"The key for the tailscale instance",
	)
)

func do(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	group, groupCtx := errgroup.WithContext(ctx)

	id, err := uuid.NewV7()
	if err != nil {
		return err
	}

	srv := ssh.NewServer(tsKey.MustValue(), id.String())
	group.Go(func() error {
		return srv.Start(groupCtx)
	})
	defer srv.Close()

	ctrl := control.Server{}
	group.Go(func() error {
		return ctrl.Start(groupCtx)
	})

	p, err := process.RunFromArgs(ctx)
	if err != nil && err != process.ErrNoCommand {
		return err
	} else if err == process.ErrNoCommand {
		<-ctx.Done()
		return nil
	}
	defer p.Cancel()

	return nil
}

func main() {
	config.Init()

	if err := do(context.Background()); err != nil {
		log.Fatalf("Failed to do this %s", err)
	}
}
