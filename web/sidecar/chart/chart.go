package chart

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sidecar/values"
	"strings"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/chartutil"
)

var ValidationError = errors.New("chart validation error")

type Chart struct {
	template *Template
	params   *Params

	parent               *Chart
	localDependencies    []*Chart
	externalDependencies []*ExternalChart
}

type ExternalChart struct {
	Name    string
	Version string
	URL     string
}

type ChartArchive struct {
	Name string
	Data []byte
}

func LoadFromArchive(archive *ChartArchive, params *Params) (*Chart, error) {
	chart, err := loader.LoadArchive(bytes.NewReader(archive.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to load chart from archive: %w", err)
	}

	parent := &Chart{template: &Template{chart: chart}, params: params}

	for _, dep := range chart.Dependencies() {
		parent.AddService(&Chart{template: &Template{chart: dep}, params: &Params{}})
	}

	return parent, nil
}

func (c *Chart) AddService(service *Chart) {
	c.localDependencies = append(c.localDependencies, service)
	service.parent = c
	c.template.chart.AddDependency(service.template.chart)
	c.template.chart.Metadata.Dependencies = append(c.template.chart.Metadata.Dependencies, &chart.Dependency{
		Name:    service.template.chart.Metadata.Name,
		Version: service.template.chart.Metadata.Version,
	})
}

func (c *Chart) AddExternalDependency(name, version, repositoryURL string) {
	c.externalDependencies = append(c.externalDependencies, &ExternalChart{
		Name:    name,
		Version: version,
		URL:     repositoryURL,
	})
	c.template.chart.Metadata.Dependencies = append(c.template.chart.Metadata.Dependencies, &chart.Dependency{
		Name:       name,
		Version:    version,
		Repository: repositoryURL,
	})
}

func (c *Chart) ClientFacingValuesFile() (*values.File, error) {
	if c.parent != nil {
		return c.params.ClientFacingValuesFile()
	}

	vs := values.Empty()
	for _, dep := range c.localDependencies {
		if _, ok := vs.Values[dep.Name()]; ok {
			return nil, fmt.Errorf("dependency %s already has values", dep.template.chart.Name())
		}

		depVs, err := dep.ClientFacingValuesFile()
		if err != nil {
			return nil, fmt.Errorf("failed to get client facing values file for dependency %s: %w", dep.template.chart.Name(), err)
		}

		vs.Values[dep.Name()] = depVs.Values
	}

	return vs, nil
}

func (c *Chart) ReleaseName() string {
	return fmt.Sprintf("%s-%s", c.params.ChartName, strings.ReplaceAll(c.params.ChartVersion, ".", "-"))
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

func (c *Chart) Archive() (*ChartArchive, error) {
	dir, err := os.MkdirTemp("", "chart-archive")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp dir: %w", err)
	}
	defer os.RemoveAll(dir)

	archivePath, err := chartutil.Save(c.template.chart, dir)
	if err != nil {
		return nil, fmt.Errorf("failed to save chart: %w", err)
	}

	archive, err := os.ReadFile(archivePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read chart archive: %w", err)
	}

	return &ChartArchive{Name: filepath.Base(archivePath), Data: archive}, nil
}

func (c *Chart) Values() (*values.File, error) {
	vs, err := c.params.toValues()
	if err != nil {
		return nil, fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	for _, dep := range c.localDependencies {
		if _, ok := vs.Values[dep.template.chart.Name()]; ok {
			return nil, fmt.Errorf("dependency %s already has values", dep.template.chart.Name())
		}

		vs.Values[dep.template.chart.Name()] = values.Empty().Values
	}

	return vs, nil
}

func (c *Chart) Validate() error {
	vs, err := c.Values()
	if err != nil {
		return fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	if err := chartutil.ValidateAgainstSchema(c.template.chart, vs.Values); err != nil {
		return fmt.Errorf("%w: %s", ValidationError, err.Error())
	}

	return nil
}

func (c *Chart) KubeChart() *chart.Chart {
	return c.template.chart
}

func (c *Chart) ApplyParams(params *Params) (*Chart, error) {
	chart, err := c.template.ApplyParams(params)
	if err != nil {
		return nil, fmt.Errorf("failed to apply params: %w", err)
	}

	chart.params = params

	return chart, nil
}

func New(template *Template, params *Params) *Chart {
	return &Chart{template: template, params: params}
}
