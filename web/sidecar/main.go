package main

import (
	"context"
	"log"
	"net/url"

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

	chart, err = chart.ApplyParams(&sidecarchart.Params{
		ChartName:    "sidecar",
		ChartVersion: "0.2.0",

		ReplicaCount: 1,
		Environment: sidecarchart.Environment{
			"FOO": "BAR",
		},
	})
	if err != nil {
		log.Fatalf("Error applying params: %v", err)
	}

	repo, err := repo.NewClient(ctx, modules.Store, &url.URL{}) // TODO: get base URL from env
	if err != nil {
		log.Fatalf("Error creating repo client: %v", err)
	}

	err = repo.Add(ctx, chart, "sidecar")
	if err != nil {
		log.Fatalf("Error adding chart to repo: %v", err)
	}
}
