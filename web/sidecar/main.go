package main

import (
	"context"
	"log"
	"strings"

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

	// versions, err := chart.Capabilities()
	// if err != nil {
	// 	log.Fatalf("Error getting capabilities: %v", err)
	// }

	// log.Printf("Supported versions: %v", strings.Join(filteredCapabilities(versions, "gke"), "\n"))

	if err := modules.Server.Run(ctx); err != nil {
		log.Fatalf("Error running server: %v", err)
	}
}

func filteredCapabilities(capabilities []string, match string) []string {
	var filtered []string
	for _, c := range capabilities {
		if strings.Contains(c, match) {
			filtered = append(filtered, c)
		}
	}
	return filtered
}
