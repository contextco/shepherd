package main

import (
	"context"
	"log"
	"os"
	"time"

	"onprem/agent"
	"onprem/config"
)

var (
	name = config.Define(
		"name",
		"default",
		"The name of the process",
	)

	bearerToken = config.Define(
		"bearer-token",
		"",
		"The bearer token to authenticate with the backend",
	)

	backendAddr = config.Define(
		"backend-addr",
		"",
		"The address of the backend",
	)

	// bug here: when setting value it converts time to ns, eg. setting to 2s will be 2ns
	heartbeatInterval = config.Define(
		"heartbeat-interval",
		30*time.Second,
		"The interval at which to send heartbeats",
	)

	planInterval = config.Define(
		"plan-interval",
		time.Minute,
		"The interval at which to plan",
	)
)

func main() {
	config.Init(os.Args[1:])

	log.Printf("Starting agent with name %s", name.MustValue())

	agent, err := agent.NewAgent(name.MustValue(), backendAddr.MustValue(), bearerToken.MustValue())
	if err != nil {
		log.Fatalf("Failed to create agent: %s", err)
	}

	log.Println("Agent created, starting heartbeat")

	agent.Start(context.Background(), heartbeatInterval.MustValue(), planInterval.MustValue())
}
