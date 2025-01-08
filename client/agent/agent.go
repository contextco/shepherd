package agent

import (
	"context"
	"log"
	"onprem/backend"
	"onprem/cluster"
	"onprem/generated/service_pb"
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

	go func() {
		fn := func() error {
			a.apply(ctx)
			return nil
		}

		if err := periodic.RunWithJitter(ctx, fn, 5*time.Minute, 20*time.Second); err != nil {
			log.Printf("Apply error: %v", err)
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

func (a *Agent) apply(ctx context.Context) {
	action, err := a.client.Apply(ctx)
	if err != nil {
		log.Printf("Apply error: %v", err)
	}

	if err := applyAction(ctx, action); err != nil {
		log.Printf("Apply error: %v", err)
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

func applyAction(ctx context.Context, action *service_pb.Action) error {
	switch action.GetAction().(type) {
	case *service_pb.Action_ApplyChart:
		return applyChart(ctx, action.GetApplyChart())
	}

	return nil
}

func applyChart(ctx context.Context, action *service_pb.ApplyChartRequest) error {
	c, err := cluster.Self(ctx)
	if err != nil {
		return err
	}

	if err := c.Install(ctx, action.GetChart(), cluster.CurrentReleaseName(), cluster.CurrentNamespace()); err != nil {
		return err
	}

	return nil
}
