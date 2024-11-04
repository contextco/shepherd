package main

import (
	"context"
	"log"

	sidecarchart "sidecar/chart"
)

const releaseName = "sidecar"

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	chart, err := sidecarchart.Empty(releaseName)
	if err != nil {
		log.Fatalf("Error creating chart: %v", err)
	}

	err = chart.Uninstall()
	if err != nil {
		log.Fatalf("Error uninstalling chart: %v", err)
	}

	err = chart.Install(ctx)
	if err != nil {
		log.Fatalf("Error installing chart: %v", err)
	}
}
