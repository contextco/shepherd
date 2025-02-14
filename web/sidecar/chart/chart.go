package chart

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"sidecar/generated/sidecar_pb"
	"sidecar/values"
	"strings"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/chartutil"
	"helm.sh/helm/v3/pkg/cli"
	"helm.sh/helm/v3/pkg/downloader"
	"helm.sh/helm/v3/pkg/getter"
	"helm.sh/helm/v3/pkg/registry"
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
		overrides = append(overrides, &values.Override{
			Path:  strings.Join([]string{proto.GetValuesAlias(), o.GetPath()}, "."),
			Value: o.GetValue().AsInterface(),
		})
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

	if err := chartutil.SaveDir(c.template.chart, dir); err != nil {
		return nil, fmt.Errorf("failed to save chart: %w", err)
	}

	if len(c.services) > 0 || len(c.externalDeps) > 0 {
		chartsDir := filepath.Join(dir, c.name, "charts")
		if err := unarchiveAllCharts(chartsDir); err != nil {
			return nil, fmt.Errorf("failed to unarchive charts: %w", err)
		}
	}

	if len(c.externalDeps) > 0 {
		if err := loadDeps(filepath.Join(dir, c.name)); err != nil {
			return nil, fmt.Errorf("failed to load dependencies: %w", err)
		}
	}

	archivePath := filepath.Join(dir, c.name, c.name+"-"+c.version+".tgz")

	// Create tar writer that writes to gzip
	var buf bytes.Buffer
	gzWriter := gzip.NewWriter(&buf)
	tarWriter := tar.NewWriter(gzWriter)

	// Walk the directory and add files to tar
	err = filepath.WalkDir(filepath.Join(dir, c.name), func(path string, info fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Get relative path from base dir
		relPath, err := filepath.Rel(filepath.Join(dir, c.name), path)
		if err != nil {
			return fmt.Errorf("failed to get relative path: %w", err)
		}

		// Skip the root directory itself
		if relPath == "." {
			return nil
		}

		finfo, err := info.Info()
		if err != nil {
			return fmt.Errorf("failed to get file info: %w", err)
		}

		// Create tar header
		header, err := tar.FileInfoHeader(finfo, "")
		if err != nil {
			return fmt.Errorf("failed to create tar header: %w", err)
		}
		header.Name = filepath.Join(c.name, relPath)

		// Write header
		if err := tarWriter.WriteHeader(header); err != nil {
			return fmt.Errorf("failed to write tar header: %w", err)
		}

		// If it's a file, write the contents
		if !info.IsDir() {
			data, err := os.ReadFile(path)
			if err != nil {
				return fmt.Errorf("failed to read file %s: %w", path, err)
			}
			if _, err := tarWriter.Write(data); err != nil {
				return fmt.Errorf("failed to write file contents to tar: %w", err)
			}
		}

		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to walk directory: %w", err)
	}

	// Close writers
	if err := tarWriter.Close(); err != nil {
		return nil, fmt.Errorf("failed to close tar writer: %w", err)
	}
	if err := gzWriter.Close(); err != nil {
		return nil, fmt.Errorf("failed to close gzip writer: %w", err)
	}

	log.Println("archivePath", archivePath)

	// Write the archive to disk
	if err := os.WriteFile(archivePath, buf.Bytes(), 0644); err != nil {
		return nil, fmt.Errorf("failed to write archive file: %w", err)
	}

	archiveWithDeps, err := os.ReadFile(archivePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read chart archive: %w", err)
	}

	return &ChartArchive{Name: filepath.Base(archivePath), Data: archiveWithDeps}, nil
}

func unarchiveAllCharts(dir string) error {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return fmt.Errorf("failed to read charts directory: %w", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".tgz") {
			chartPath := filepath.Join(dir, entry.Name())
			chart, err := loader.LoadFile(chartPath)
			if err != nil {
				return fmt.Errorf("failed to load chart %s: %w", entry.Name(), err)
			}

			if err := chartutil.SaveDir(chart, dir); err != nil {
				return fmt.Errorf("failed to unarchive chart %s: %w", entry.Name(), err)
			}

			if err := os.Remove(chartPath); err != nil {
				return fmt.Errorf("failed to remove chart archive %s: %w", entry.Name(), err)
			}
		}
	}

	return nil
}

func loadDeps(dir string) error {
	rc, err := registry.NewClient()
	if err != nil {
		return fmt.Errorf("failed to create registry client: %w", err)
	}

	m := downloader.Manager{
		ChartPath:      dir,
		Out:            os.Stderr,
		Getters:        getter.All(&cli.EnvSettings{}),
		RegistryClient: rc,
	}

	if err := m.Build(); err != nil {
		return fmt.Errorf("failed to update dependencies: %w", err)
	}

	return nil
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
