package main

import (
	"context"
	"log"

	_ "github.com/joho/godotenv/autoload" // load env vars
)

const releaseName = "sidecar"

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	modules, err := ModulesFromEnv(ctx)
	if err != nil {
		log.Fatalf("Error creating modules: %v", err)
	}

	if err := modules.Server.Run(ctx); err != nil {
		log.Fatalf("Error running server: %v", err)
	}
}
