package main

import (
	"context"
	"log"
	"math"
	"os"
	"time"

	"github.com/google/uuid"

	"onprem/backend"
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
)

type Agent struct {
	LifecycleID string
	Name        string

	client  *backend.Client // gRPC client which sends heartbeats
}

func (a *Agent) Start(ctx context.Context) {
	go func() {
		log.Printf("Starting heartbeat for %s", a.Name)
		backoff := time.Second // Initial backoff duration
		maxBackoff := time.Minute * 5

		for {
			select {
			case <-ctx.Done():
				log.Println("Heartbeat stopped: context cancelled")
				return
			default:
				if err := a.heartbeat(ctx); err != nil {
					log.Printf("Heartbeat error: %v, retrying in %v", err, backoff)
					time.Sleep(backoff)
					// Exponential backoff with max cap
					backoff = time.Duration(math.Min(
						float64(backoff*2), 
						float64(maxBackoff),
					))
				} else {
					// Reset backoff on success
					backoff = time.Second
				}
			}
		}
	}()
	
	<-ctx.Done()
	log.Printf("Agent stopped: context cancelled")
}

func (a *Agent) heartbeat(ctx context.Context) error {
	log.Printf("Sending heartbeat for %s", a.Name)
	log.Printf("Lifecycle ID: %s", a.LifecycleID)
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

	log.Printf("Creating client with backend address %s, and token: %s", backendAddr.MustValue(), bearerToken.MustValue())
	client, err := backend.NewClient(backendAddr.MustValue(), bearerToken.MustValue(), backend.Identity{
		LifecycleID: id,
		Name:        name.MustValue(),
	})
	if err != nil {
		return nil, err
	}

	return &Agent{
		LifecycleID: id,
		Name:        name.MustValue(),

		client:  client,
	}, nil
}

func main() {
	config.Init(os.Args[1:])

	log.Printf("Starting agent with name %s", name.MustValue())

	agent, err := NewAgent()
	if err != nil {
		log.Fatalf("Failed to create agent: %s", err)
	}

	log.Println("Agent created, starting heartbeat")

	agent.Start(context.Background())
}
