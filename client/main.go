package main

import (
	"context"
	"log"
	"time"

	"github.com/google/uuid"

	"onprem/backend"
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

	name = config.Define(
		"name",
		"",
		"The name of the process",
	)

	backendAddr = config.Define(
		"backend-addr",
		"",
		"The address of the backend",
	)

	heartbeatInterval = config.Define(
		"heartbeat-interval",
		30*time.Second,
		"The interval at which to send heartbeats",
	)
)

type Agent struct {
	LifecycleID string
	Name        string

	client  *backend.Client
	process *process.Process
	ctrl    *control.Server
}

func (a *Agent) Start(ctx context.Context) error {
	if err := a.process.Run(ctx); err != nil && err != process.ErrNoCommand {
		return err
	}
	defer a.process.Cancel()

	go func() {
		if err := a.heartbeat(ctx); err != nil {
			log.Fatalf("Failed to heartbeat: %s", err)
		}
	}()

	return a.ctrl.Start(ctx)
}

func (a *Agent) heartbeat(ctx context.Context) error {
	ticker := time.NewTicker(heartbeatInterval.MustValue())
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			if err := a.client.Heartbeat(ctx); err != nil {
				return err
			}
		}
	}
}

func NewAgent() (*Agent, error) {
	id := uuid.New().String()

	p, err := process.NewFromArgs(context.Background())
	if err != nil {
		return nil, err
	}

	client, err := backend.NewClient(backendAddr.MustValue(), "", backend.Identity{
		LifecycleID: id,
		Name:        name.MustValue(),
	})
	if err != nil {
		return nil, err
	}

	ctrl, err := control.New(tsKey.MustValue(), p)
	if err != nil {
		return nil, err
	}

	return &Agent{
		LifecycleID: id,
		Name:        name.MustValue(),

		process: p,
		client:  client,
		ctrl:    ctrl,
	}, nil
}

func main() {
	config.Init()

	agent, err := NewAgent()
	if err != nil {
		log.Fatalf("Failed to create agent: %s", err)
	}

	agent.Start(context.Background())
}
