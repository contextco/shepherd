package chart

import (
	"context"
	"fmt"
	"log"
	"os"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chartutil"
	"k8s.io/cli-runtime/pkg/genericclioptions"
)

type Chart struct {
	releaseName string

	template *Template
	params   *Params
}

func (c *Chart) Name() string {
	return c.params.ChartName
}

func (c *Chart) Version() string {
	return c.params.ChartVersion
}

func (c *Chart) Metadata() *chart.Metadata {
	return c.template.chart.Metadata
}

func (c *Chart) Archive(dir string) (string, error) {
	values, err := c.params.toValues()
	if err != nil {
		return "", fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	c.template.chart.Values = values
	return chartutil.Save(c.template.chart, dir)
}

func (c *Chart) Validate() error {
	values, err := c.params.toValues()
	if err != nil {
		return fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	if err := chartutil.ValidateAgainstSchema(c.template.chart, values); err != nil {
		return fmt.Errorf("failed to validate chart: %w", err)
	}

	return nil
}

func (c *Chart) Install(ctx context.Context) error {
	actionConfig, err := actionConfig()
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewInstall(actionConfig)
	client.Namespace = "default"
	client.ReleaseName = c.releaseName
	client.Replace = true

	rel, err := client.RunWithContext(ctx, c.template.chart, nil)
	if err != nil {
		return fmt.Errorf("failed to install chart: %w", err)
	}

	log.Printf("Successfully installed release %s", rel.Name)
	return nil
}

func (c *Chart) Uninstall() error {
	actionConfig, err := actionConfig()
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewUninstall(actionConfig)
	client.IgnoreNotFound = true

	_, err = client.Run(c.releaseName)
	if err != nil {
		return fmt.Errorf("failed to uninstall chart: %w", err)
	}

	log.Printf("Successfully uninstalled release %s", c.releaseName)
	return nil
}

func New(releaseName string, template *Template, params *Params) *Chart {
	return &Chart{releaseName: releaseName, template: template, params: params}
}

func actionConfig() (*action.Configuration, error) {
	s := newSettings()
	actionConfig := new(action.Configuration)
	if err := actionConfig.Init(s.RESTClientGetter(), "default", os.Getenv("HELM_DRIVER"), log.Printf); err != nil {
		return nil, fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	return actionConfig, nil
}

type settings struct {
	config *genericclioptions.ConfigFlags
}

func (s *settings) RESTClientGetter() genericclioptions.RESTClientGetter {
	return s.config
}

func newSettings() *settings {
	return &settings{
		config: genericclioptions.NewConfigFlags(true),
	}
}
