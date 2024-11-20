package chart

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sidecar/generated/sidecar_pb"
	"sidecar/values"
	"strings"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/chartutil"
)

var ValidationError = errors.New("chart validation error")

type Chart struct {
	name     string
	version  string
	template *Template
}

type ExternalChart struct {
	Name      string
	Version   string
	URL       string
	Overrides []*values.Override
}

type ChartArchive struct {
	Name string
	Data []byte
}

type ParentChart struct {
	*Chart

	services     []*ServiceChart
	externalDeps []*ExternalChart
}

func (pc *ParentChart) AddService(service *ServiceChart) error {
	pc.services = append(pc.services, service)
	service.parent = pc
	pc.template.chart.AddDependency(service.template.chart)
	pc.template.chart.Metadata.Dependencies = append(pc.template.chart.Metadata.Dependencies, &chart.Dependency{
		Name:    service.template.chart.Metadata.Name,
		Version: service.template.chart.Metadata.Version,
	})

	return pc.SyncValues()
}

type ServiceChart struct {
	*Chart
	parent *ParentChart
	params *Params
}

func LoadFromArchive(archive *ChartArchive) (*ParentChart, error) {
	chart, err := loader.LoadArchive(bytes.NewReader(archive.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to load chart from archive: %w", err)
	}

	parent := &ParentChart{Chart: &Chart{name: chart.Metadata.Name, version: chart.Metadata.Version, template: &Template{chart: chart}}}

	for _, dep := range chart.Dependencies() {
		s, err := NewServiceChart(dep.Metadata.Name, dep.Metadata.Version, &Params{})
		if err != nil {
			return nil, fmt.Errorf("failed to create service chart for dependency %s: %w", dep.Metadata.Name, err)
		}
		if err := parent.AddService(s); err != nil {
			return nil, fmt.Errorf("failed to add service chart for dependency %s: %w", dep.Metadata.Name, err)
		}
	}

	return parent, nil
}

func (c *ParentChart) AddExternalDependencyFromProto(proto *sidecar_pb.DependencyParams) error {
	overrides := []*values.Override{}
	for _, o := range proto.GetOverrides() {
		overrides = append(overrides, &values.Override{Path: o.GetPath(), Value: o.GetValue().AsInterface()})
	}

	c.externalDeps = append(c.externalDeps, &ExternalChart{
		Name:      proto.GetName(),
		Version:   proto.GetVersion(),
		URL:       proto.GetRepositoryUrl(),
		Overrides: overrides,
	})
	c.template.chart.Metadata.Dependencies = append(c.template.chart.Metadata.Dependencies, &chart.Dependency{
		Name:       proto.GetName(),
		Version:    proto.GetVersion(),
		Repository: proto.GetRepositoryUrl(),
	})

	return c.SyncValues()
}

func (c *ParentChart) ClientFacingValuesFile() (*values.File, error) {
	vs := values.Empty()
	for _, dep := range c.services {
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

func (sc *ServiceChart) ClientFacingValuesFile() (*values.File, error) {
	return sc.params.ClientFacingValuesFile()
}

func (c *Chart) ReleaseName() string {
	return fmt.Sprintf("%s-%s", c.name, strings.ReplaceAll(c.version, ".", "-"))
}

func (c *Chart) Name() string {
	return c.name
}

func (c *Chart) Version() string {
	return c.version
}

func (c *Chart) Metadata() *chart.Metadata {
	return c.template.chart.Metadata
}

func (c *ParentChart) Archive() (*ChartArchive, error) {
	if err := c.SyncValues(); err != nil {
		return nil, fmt.Errorf("failed to sync values: %w", err)
	}

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

func (c *ParentChart) Values() (*values.File, error) {
	vs := values.Empty()
	for _, dep := range c.services {
		if _, ok := vs.Values[dep.template.chart.Name()]; ok {
			return nil, fmt.Errorf("dependency %s already has values", dep.template.chart.Name())
		}

		vs.Values[dep.template.chart.Name()] = values.Empty().Values
	}

	for _, dep := range c.externalDeps {
		for _, o := range dep.Overrides {
			if err := vs.ApplyOverride(o); err != nil {
				return nil, fmt.Errorf("failed to apply override %s: %w", o.Path, err)
			}
		}
	}

	return vs, nil
}

func (sc *ServiceChart) Values() (*values.File, error) {
	return sc.params.toValues()
}

func (c *ParentChart) Validate() error {
	vs, err := c.Values()
	if err != nil {
		return fmt.Errorf("failed to get values: %w", err)
	}

	for _, dep := range c.services {
		if err := dep.Validate(vs); err != nil {
			return err
		}
	}

	return nil
}

func (c *Chart) Validate(values *values.File) error {
	if err := chartutil.ValidateAgainstSchema(c.template.chart, values.Values); err != nil {
		return fmt.Errorf("%w: %s", ValidationError, err.Error())
	}

	return nil
}

func (c *Chart) KubeChart() *chart.Chart {
	return c.template.chart
}

func (c *ParentChart) SyncValues() error {
	c.template.chart.Metadata.Name = c.name
	c.template.chart.Metadata.Version = c.version

	for _, dep := range c.services {
		if err := dep.SyncValues(); err != nil {
			return fmt.Errorf("failed to sync values for dependency %s: %w", dep.template.chart.Name(), err)
		}
	}

	vals, err := c.Values()
	if err != nil {
		return fmt.Errorf("failed to get values: %w", err)
	}

	return c.template.SetValues(vals)
}

func (c *ServiceChart) SyncValues() error {
	vals, err := c.Values()
	if err != nil {
		return fmt.Errorf("failed to get values: %w", err)
	}

	c.template.chart.Metadata.Name = c.name
	c.template.chart.Metadata.Version = c.version

	return c.template.SetValues(vals)
}

func New(name, version string, template *Template) *Chart {
	return &Chart{name: name, version: version, template: template}
}
