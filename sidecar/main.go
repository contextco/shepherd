package main

import (
	"context"
	"log"

	sidecarchart "sidecar/chart"
	"sidecar/repo"

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

	chart, err := sidecarchart.Empty(releaseName)
	if err != nil {
		log.Fatalf("Error creating chart: %v", err)
	}

	repo, err := repo.NewClient(ctx, modules.Store)
	if err != nil {
		log.Fatalf("Error creating repo client: %v", err)
	}

	err = repo.Add(ctx, chart, "sidecar")
	if err != nil {
		log.Fatalf("Error adding chart to repo: %v", err)
	}
}
