package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"k8s.io/cli-runtime/pkg/genericclioptions"
)

const releaseName = "sidecar"

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	chart, err := createChart()
	if err != nil {
		log.Fatalf("Error creating chart: %v", err)
	}

	fmt.Println(chart.Validate())

	err = uninstallChart()
	if err != nil {
		log.Fatalf("Error uninstalling chart: %v", err)
	}

	err = installChart(ctx, chart)
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

func uninstallChart() error {
	actionConfig, err := actionConfig()
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewUninstall(actionConfig)
	client.IgnoreNotFound = true

	_, err = client.Run(releaseName)
	if err != nil {
		return fmt.Errorf("failed to uninstall chart: %w", err)
	}

	return nil
}

func installChart(ctx context.Context, chart *chart.Chart) error {
	actionConfig, err := actionConfig()
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewInstall(actionConfig)
	client.Namespace = "default"
	client.ReleaseName = releaseName
	client.Replace = true

	rel, err := client.RunWithContext(ctx, chart, nil)
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

	for _, file := range files {
		fmt.Printf("file: %s\n", file.Name)
	}

	chart, err := loader.LoadFiles(files)
	if err != nil {
		return nil, err
	}

	return chart, nil
}

func actionConfig() (*action.Configuration, error) {
	s := NewSettings()
	actionConfig := new(action.Configuration)
	if err := actionConfig.Init(s.RESTClientGetter(), "default", os.Getenv("HELM_DRIVER"), log.Printf); err != nil {
		return nil, fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	return actionConfig, nil
}
