package chart

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sidecar/values"
	"strings"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/chartutil"
	"k8s.io/apimachinery/pkg/api/meta"
	"k8s.io/client-go/discovery"
	"k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/clientcmd"
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

func (c *Chart) releaseName() string {
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

// TODO: Install + Uninstall should really be methods on cluster.
func (c *Chart) Install(ctx context.Context, kubeConfig []byte) error {
	if err := c.Validate(); err != nil {
		return fmt.Errorf("failed to validate chart: %w", err)
	}

	actionConfig, err := actionConfig(kubeConfig)
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewInstall(actionConfig)
	client.Namespace = "default"
	client.ReleaseName = c.releaseName()
	client.Replace = true

	rel, err := client.RunWithContext(ctx, c.template.chart, nil)
	if err != nil {
		return fmt.Errorf("failed to install chart: %w", err)
	}

	log.Printf("Successfully installed release %s", rel.Name)
	return nil
}

func (c *Chart) Uninstall(kubeConfig []byte) error {
	actionConfig, err := actionConfig(kubeConfig)
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewUninstall(actionConfig)
	client.IgnoreNotFound = true

	_, err = client.Run(c.releaseName())
	if err != nil {
		return fmt.Errorf("failed to uninstall chart: %w", err)
	}

	log.Printf("Successfully uninstalled release %s", c.releaseName())
	return nil
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

func actionConfig(kubeConfig []byte) (*action.Configuration, error) {
	rcg, err := newRestClientGetter(kubeConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create rest client getter: %w", err)
	}

	actionConfig := new(action.Configuration)
	if err := actionConfig.Init(rcg, "default", os.Getenv("HELM_DRIVER"), log.Printf); err != nil {
		return nil, fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	return actionConfig, nil
}

type restClientGetter struct {
	clientConfig clientcmd.ClientConfig
}

func (r *restClientGetter) ToRESTConfig() (*rest.Config, error) {
	return r.clientConfig.ClientConfig()
}

func (r *restClientGetter) ToRESTMapper() (meta.RESTMapper, error) {
	dc, err := r.ToDiscoveryClient()
	if err != nil {
		return nil, err
	}
	return restmapper.NewDeferredDiscoveryRESTMapper(dc), nil
}

func (r *restClientGetter) ToRawKubeConfigLoader() clientcmd.ClientConfig {
	return r.clientConfig
}

func (r *restClientGetter) ToDiscoveryClient() (discovery.CachedDiscoveryInterface, error) {
	restConfig, err := r.clientConfig.ClientConfig()
	if err != nil {
		return nil, fmt.Errorf("failed to create discovery client: %w", err)
	}

	dc, err := discovery.NewDiscoveryClientForConfig(restConfig)
	if err != nil {
		return nil, err
	}
	return memory.NewMemCacheClient(dc), nil
}

func newRestClientGetter(kubeConfig []byte) (*restClientGetter, error) {
	clientconfig, err := clientcmd.NewClientConfigFromBytes(kubeConfig)
	if err != nil {
		return nil, err
	}

	rawconfig, err := clientconfig.RawConfig()
	if err != nil {
		return nil, err
	}

	clientconfig = clientcmd.NewDefaultClientConfig(rawconfig, &clientcmd.ConfigOverrides{})

	return &restClientGetter{clientConfig: clientconfig}, nil
}

func Capabilities(kubeConfig []byte) ([]string, error) {
	rcg, err := newRestClientGetter(kubeConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create rest client getter: %w", err)
	}

	dc, err := rcg.ToDiscoveryClient()
	if err != nil {
		return nil, fmt.Errorf("failed to create discovery client: %w", err)
	}

	versions, err := action.GetVersionSet(dc)
	if err != nil {
		return nil, fmt.Errorf("failed to get version set: %w", err)
	}

	return versions, nil
}
