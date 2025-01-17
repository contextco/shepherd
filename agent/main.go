package main

import (
	"context"
	"log"
	"os"
	"time"

	"agent/agent"
	"agent/config"
)

var (
	cfg = Config{
		Name: config.Define(
			"name",
			"",
			"The name of the agent",
		),
		BearerToken: config.Define(
			"bearer-token",
			"",
			"The bearer token to authenticate with the backend",
		),
		BackendAddr: config.Define(
			"backend-addr",
			"",
			"The address of the backend",
		),
		HeartbeatInterval: config.Define(
			"heartbeat-interval",
			30*time.Second,
			"The interval at which to send heartbeats",
		),
		PlanInterval: config.Define(
			"plan-interval",
			time.Minute,
			"The interval at which to plan",
		),
		Version: config.Define(
			"shepherd-project-version-id",
			"",
			"The version of the shepherd project",
		),
	}
)

func main() {
	config.Init(os.Args[1:])

	log.Printf("Starting agent with name %s", cfg.Name.MustValue())

	agent, err := agent.NewAgent(agent.AgentConfig{
		Name:              cfg.Name.MustValue(),
		BackendAddr:       cfg.BackendAddr.MustValue(),
		BearerToken:       cfg.BearerToken.MustValue(),
		HeartbeatInterval: cfg.HeartbeatInterval.MustValue(),
		PlanInterval:      cfg.PlanInterval.MustValue(),
		VersionID:         cfg.Version.MustValue(),
	})
	if err != nil {
		log.Fatalf("Failed to create agent: %s", err)
	}

	log.Println("Agent created, starting heartbeat")

	agent.Start(context.Background())
}

type Config struct {
	Name              *config.ConfigVar[string]
	BearerToken       *config.ConfigVar[string]
	BackendAddr       *config.ConfigVar[string]
	HeartbeatInterval *config.ConfigVar[time.Duration]
	PlanInterval      *config.ConfigVar[time.Duration]
	Version           *config.ConfigVar[string]
}
