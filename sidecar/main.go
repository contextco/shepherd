package main

import (
	"fmt"
	"log"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
)

func main() {
	chart, err := createChart()
	if err != nil {
		log.Fatalf("Error creating chart: %v", err)
	}

	fmt.Println(chart.Validate())
}

func createChart() (*chart.Chart, error) {
	files, err := TemplateFiles()
	if err != nil {
		return nil, err
	}

	chart, err := loader.LoadFiles(files)
	if err != nil {
		return nil, err
	}

	return chart, nil
}
