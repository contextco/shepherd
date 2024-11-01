package main

import (
	"fmt"
	"log"
	"os"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"k8s.io/cli-runtime/pkg/genericclioptions"
)

func main() {
	chart, err := createChart()
	if err != nil {
		log.Fatalf("Error creating chart: %v", err)
	}

	fmt.Println(chart.Validate())

	err = installChart(chart)
	if err != nil {
		log.Fatalf("Error installing chart: %v", err)
	}
}

type settings struct {
	config *genericclioptions.ConfigFlags
}

func (s *settings) RESTClientGetter() genericclioptions.RESTClientGetter {
	return s.config
}

func NewSettings() *settings {
	return &settings{
		config: genericclioptions.NewConfigFlags(true),
	}
}

func installChart(chart *chart.Chart) error {
	s := NewSettings()
	actionConfig := new(action.Configuration)
	if err := actionConfig.Init(s.RESTClientGetter(), "default", os.Getenv("HELM_DRIVER"), log.Printf); err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewInstall(actionConfig)
	client.Namespace = "default"
	client.ReleaseName = "my-release"

	rel, err := client.Run(chart, nil)
	if err != nil {
		return fmt.Errorf("failed to install chart: %w", err)
	}

	log.Printf("Successfully installed release %s", rel.Name)
	return nil
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
