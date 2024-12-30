package agent

import (
	"context"
	"log"
	"onprem/backend"
	"onprem/periodic"
	"time"

	"github.com/google/uuid"
)

type Agent struct {
	LifecycleID string
	Name        string

	client *backend.Client // gRPC client which sends heartbeats
}

func (a *Agent) Start(ctx context.Context, heartbeatInterval time.Duration) {
	go func() {
		fn := func() error {
			a.heartbeat(ctx)
			return nil
		}

		if err := periodic.RunWithJitter(ctx, fn, heartbeatInterval, 500*time.Millisecond); err != nil {
			log.Printf("Heartbeat error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Printf("Agent stopped: context cancelled")
}

func (a *Agent) heartbeat(ctx context.Context) {
	log.Printf("Sending heartbeat for %s", a.Name)
	log.Printf("Lifecycle ID: %s", a.LifecycleID)

	if err := a.client.Heartbeat(ctx); err != nil {
		// Eat the error, we don't want to crash the agent.
		log.Printf("Heartbeat error: %v", err)
	}
}

func NewAgent(name, backendAddr, bearerToken string) (*Agent, error) {
	id := uuid.New().String()

	log.Printf("Creating client with backend address %s, and token: %s", backendAddr, bearerToken)
	client, err := backend.NewClient(backendAddr, bearerToken, backend.Identity{
		LifecycleID: id,
		Name:        name,
	})
	if err != nil {
		return nil, err
	}

	return &Agent{
		LifecycleID: id,
		Name:        name,

		client: client,
	}, nil
}
