package agent

import (
	"agent/backend"
	"agent/cluster"
	"agent/generated/service_pb"
	"agent/lifecycleid"
	"agent/periodic"
	"context"
	"log"
	"time"

	"github.com/google/uuid"
)

type Agent struct {
	LifecycleID string
	SessionID   string

	client *backend.Client // gRPC client which sends heartbeats

	cfg AgentConfig
}

type AgentConfig struct {
	Name string

	BackendAddr string
	BearerToken string

	HeartbeatInterval time.Duration
	PlanInterval      time.Duration
	VersionID         string

	LifecycleIDFilePath string
}

func (a *Agent) Start(ctx context.Context) {
	go func() {
		fn := func() error {
			a.heartbeat(ctx)
			return nil
		}

		if err := periodic.RunWithJitter(ctx, fn, a.cfg.HeartbeatInterval, 500*time.Millisecond); err != nil {
			log.Printf("Heartbeat error: %v", err)
		}
	}()

	go func() {
		fn := func() error {
			a.apply(ctx)
			return nil
		}

		if err := periodic.RunWithJitter(ctx, fn, a.cfg.PlanInterval, 20*time.Second); err != nil {
			log.Printf("Apply error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Printf("Agent stopped: context cancelled")
}

func (a *Agent) heartbeat(ctx context.Context) {
	log.Printf("Sending heartbeat for %s", a.cfg.Name)
	log.Printf("Lifecycle ID: %s", a.LifecycleID)
	log.Printf("Session ID: %s", a.SessionID)

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

func NewAgent(cfg AgentConfig) (*Agent, error) {
	lifecycleID := lifecycleid.NewLifecycleIDGenerator(cfg.LifecycleIDFilePath).Generate()
	sessionID := uuid.New().String()

	log.Printf("Creating client with backend address %s, and token: %s", cfg.BackendAddr, cfg.BearerToken)
	client, err := backend.NewClient(cfg.BackendAddr, cfg.BearerToken, backend.Identity{
		LifecycleID: lifecycleID,
		SessionID:   sessionID,
		Name:        cfg.Name,
		VersionID:   cfg.VersionID,
	})
	if err != nil {
		return nil, err
	}

	return &Agent{
		LifecycleID: lifecycleID,
		SessionID:   sessionID,
		client:      client,
		cfg:         cfg,
	}, nil
}

func applyAction(ctx context.Context, action *service_pb.Action) error {
	switch action.GetAction().(type) {
	case *service_pb.Action_ApplyChart:
		return applyChart(ctx, action.GetApplyChart())
	}

	log.Printf("No action to take.")

	return nil
}

func applyChart(ctx context.Context, action *service_pb.ApplyChartRequest) error {
	log.Printf("Applying chart action.")
	c, err := cluster.Self(ctx)
	if err != nil {
		return err
	}

	if err := c.Upgrade(ctx, action.GetChart(), cluster.CurrentReleaseName(), cluster.CurrentNamespace()); err != nil {
		return err
	}

	log.Printf("Chart applied.")

	return nil
}
