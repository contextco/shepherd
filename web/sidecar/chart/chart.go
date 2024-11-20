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
	template *Template
	params   *Params
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

func (pc *ParentChart) AddService(service *ServiceChart) {
	pc.services = append(pc.services, service)
	service.parent = pc
	pc.template.chart.AddDependency(service.template.chart)
	pc.template.chart.Metadata.Dependencies = append(pc.template.chart.Metadata.Dependencies, &chart.Dependency{
		Name:    service.template.chart.Metadata.Name,
		Version: service.template.chart.Metadata.Version,
	})
}

type ServiceChart struct {
	*Chart
	parent *ParentChart
}

func LoadFromArchive(archive *ChartArchive, params *Params) (*ParentChart, error) {
	chart, err := loader.LoadArchive(bytes.NewReader(archive.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to load chart from archive: %w", err)
	}

	parent := &ParentChart{Chart: &Chart{template: &Template{chart: chart}, params: params}}

	for _, dep := range chart.Dependencies() {
		parent.AddService(&ServiceChart{Chart: &Chart{template: &Template{chart: dep}, params: &Params{}}})
	}

	return parent, nil
}

func (c *ParentChart) AddExternalDependencyFromProto(proto *sidecar_pb.DependencyParams) {
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

func (c *Chart) ApplyParams(params *Params) error {
	c.params = params
	return c.template.ApplyParams(params)
}

func New(template *Template, params *Params) *Chart {
	return &Chart{template: template, params: params}
}
