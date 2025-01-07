package cluster

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/chart/loader"
	"k8s.io/apimachinery/pkg/api/meta"
	"k8s.io/client-go/discovery"
	"k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/clientcmd/api"
)

const (
	HELM_RELEASE_NAME_ENV_KEY = "HELM_RELEASE_NAME"
	HELM_NAMESPACE_ENV_KEY    = "HELM_NAMESPACE"
)

type Cluster struct {
	clientset *kubernetes.Clientset
}

func FromKubeConfig(ctx context.Context, kubeConfig []byte) (*Cluster, error) {
	cfg, err := clientcmd.NewClientConfigFromBytes(kubeConfig)
	if err != nil {
		return nil, err
	}

	restConfig, err := cfg.ClientConfig()
	if err != nil {
		return nil, err
	}

	clientset, err := kubernetes.NewForConfig(restConfig)
	if err != nil {
		return nil, err
	}

	return &Cluster{clientset: clientset}, nil
}

// get in-cluster config + create your clientset
func Self(ctx context.Context) (*Cluster, error) {
	config, err := rest.InClusterConfig()
	if err != nil {
		return nil, err
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, err
	}

	return &Cluster{clientset: clientset}, nil
}

func (c *Cluster) ReleaseName() string {
	return os.Getenv(HELM_RELEASE_NAME_ENV_KEY)
}

func (c *Cluster) Namespace() string {
	return os.Getenv(HELM_NAMESPACE_ENV_KEY)
}

// install a chart from the provided tar/dir/whatever (passed as []byte)
func (c *Cluster) Install(ctx context.Context, chartData []byte) error {
	// init helm action configuration
	actionCfg, err := newActionConfig()
	if err != nil {
		return err
	}

	// parse the chart from bytes
	ch, err := loader.LoadArchive(bytes.NewReader(chartData))
	if err != nil {
		return fmt.Errorf("failed to load chart: %w", err)
	}

	// create an install action
	install := action.NewInstall(actionCfg)

	// define your release name, namespace, etc.
	install.ReleaseName = c.ReleaseName()
	install.Namespace = c.Namespace()
	install.Replace = true
	install.CreateNamespace = true

	// actually install
	rel, err := install.RunWithContext(ctx, ch, map[string]any{})
	if err != nil {
		return fmt.Errorf("failed to install chart: %w", err)
	}

	log.Printf("successfully installed release %s", rel.Name)
	return nil
}

func (c *Cluster) Uninstall(ctx context.Context, chartData []byte) error {
	actionCfg, err := newActionConfig()
	if err != nil {
		return err
	}

	client := action.NewUninstall(actionCfg)
	client.IgnoreNotFound = true
	client.Wait = true

	_, err = client.Run(c.ReleaseName())
	if err != nil {
		return fmt.Errorf("failed to uninstall chart: %w", err)
	}

	log.Printf("Successfully uninstalled release %s", c.ReleaseName())
	return nil
}

// newActionConfig: build an action.Configuration from in-cluster config
func newActionConfig() (*action.Configuration, error) {
	cfg, err := rest.InClusterConfig()
	if err != nil {
		return nil, err
	}

	rcg := &myRestClientGetter{config: cfg}

	var a action.Configuration
	// third param is the helm driver (configmap, secret, memory, etc.)
	err = a.Init(rcg, "default", "secrets", log.Printf)
	if err != nil {
		return nil, err
	}

	return &a, nil
}

// implement your restclientgetter
type myRestClientGetter struct {
	config *rest.Config
}

func (m *myRestClientGetter) ToRESTConfig() (*rest.Config, error) {
	return m.config, nil
}

func (m *myRestClientGetter) ToDiscoveryClient() (discovery.CachedDiscoveryInterface, error) {
	cfg, err := m.ToRESTConfig()
	if err != nil {
		return nil, err
	}
	realDisc, err := discovery.NewDiscoveryClientForConfig(cfg)
	if err != nil {
		return nil, err
	}
	// wrap it with a memory cache
	return memory.NewMemCacheClient(realDisc), nil
}

func (m *myRestClientGetter) ToRESTMapper() (meta.RESTMapper, error) {
	dc, err := m.ToDiscoveryClient()
	if err != nil {
		return nil, err
	}
	return restmapper.NewDeferredDiscoveryRESTMapper(dc), nil
}

func (m *myRestClientGetter) ToRawKubeConfigLoader() clientcmd.ClientConfig {
	return clientcmd.NewDefaultClientConfig(
		api.Config{
			Clusters: map[string]*api.Cluster{
				"incluster": {
					Server:                   m.config.Host,
					CertificateAuthorityData: m.config.CAData,
					InsecureSkipTLSVerify:    m.config.Insecure,
				},
			},
			AuthInfos: map[string]*api.AuthInfo{
				"default": {
					Token: m.config.BearerToken,
				},
			},
			Contexts: map[string]*api.Context{
				"default": {
					Cluster:  "incluster",
					AuthInfo: "default",
				},
			},
			CurrentContext: "default",
		},
		&clientcmd.ConfigOverrides{},
	)
}
