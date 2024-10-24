package main

import (
	"context"
	"log"

	"onprem/config"
	"onprem/control"
	"onprem/process"
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

	p, err := process.RunFromArgs(ctx)
	if err != nil && err != process.ErrNoCommand {
		return err
	}
	if p != nil {
		defer p.Cancel()
	}

	log.Printf("Starting control server with process %v", p)
	ctrl, err := control.New(tsKey.MustValue(), p)
	if err != nil {
		return err
	}
	defer ctrl.Close()

	return ctrl.Start(ctx)
}

func main() {
	config.Init()

	if err := do(context.Background()); err != nil {
		log.Fatalf("Failed to do this %s", err)
	}
}
