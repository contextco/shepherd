package testcluster

import (
	"context"
	"fmt"
	"log"
	"os"
	"sidecar/chart"
	"strings"
	"testing"

	"helm.sh/helm/v3/pkg/action"
	"k8s.io/client-go/discovery"
	memory "k8s.io/client-go/discovery/cached"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Cluster represents a kind kubernetes test cluster
type Cluster struct {
	impl clusterImpl
}

type clusterImpl interface {
	create(ctx context.Context) error
	delete(ctx context.Context) error
	restConfig(ctx context.Context) (*rest.Config, error)
	getKubeConfig(ctx context.Context) ([]byte, error)
	isReusable() bool
}

func (c *Cluster) Install(ctx context.Context, ch *chart.Chart) error {
	kubeConfig, err := c.impl.getKubeConfig(ctx)
	if err != nil {
		return fmt.Errorf("failed to get kubeconfig: %w", err)
	}

	actionConfig, err := actionConfig(kubeConfig)
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewInstall(actionConfig)
	client.Namespace = "default"
	client.ReleaseName = ch.ReleaseName()
	client.Replace = true

	rel, err := client.RunWithContext(ctx, ch.KubeChart(), nil)
	if err != nil {
		return fmt.Errorf("failed to install chart: %w", err)
	}

	log.Printf("Successfully installed release %s", rel.Name)

	return nil
}

func (c *Cluster) Uninstall(ctx context.Context, ch *chart.Chart) error {
	kubeConfig, err := c.impl.getKubeConfig(ctx)
	if err != nil {
		return fmt.Errorf("failed to get kubeconfig: %w", err)
	}

	actionConfig, err := actionConfig(kubeConfig)
	if err != nil {
		return fmt.Errorf("failed to initialize helm configuration: %w", err)
	}

	client := action.NewUninstall(actionConfig)
	client.IgnoreNotFound = true

	_, err = client.Run(ch.ReleaseName())
	if err != nil {
		return fmt.Errorf("failed to uninstall chart: %w", err)
	}

	log.Printf("Successfully uninstalled release %s", ch.ReleaseName())
	return nil
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

// New creates a new test cluster with the given name
func New(t *testing.T, ctx context.Context) *Cluster {
	impl := &kindCluster{name: strings.ToLower(strings.ReplaceAll(t.Name(), "_", "-"))} // TODO: add gke impl

	cluster := &Cluster{
		impl: impl,
	}

	_ = cluster.impl.delete(ctx) // ignore error if cluster does not exist

	if err := cluster.impl.create(ctx); err != nil {
		t.Fatalf("failed to create kind cluster: %v", err)
	}

	t.Cleanup(func() {
		if err := cluster.impl.delete(context.WithoutCancel(ctx)); err != nil {
			t.Logf("failed to delete cluster: %v", err)
		}
	})

	return cluster
}

func (c *Cluster) KubeConfig(ctx context.Context) ([]byte, error) {
	return c.impl.getKubeConfig(ctx)
}

func (c *Cluster) WaitForPods(ctx context.Context, matchFunc func(*corev1.Pod) bool) error {
	clientConfig, err := c.impl.restConfig(ctx)
	if err != nil {
		return err
	}

	client, err := kubernetes.NewForConfig(clientConfig)
	if err != nil {
		return err
	}

	factory := informers.NewSharedInformerFactoryWithOptions(client, 0)
	podInformer := factory.Core().V1().Pods().Informer()

	waitC := make(chan struct{}, 1)
	handleNewPodState := func(obj any) {
		pod, ok := obj.(*corev1.Pod)
		if !ok {
			return
		}
		if matchFunc(pod) {
			waitC <- struct{}{}
		}
	}
	podInformer.AddEventHandler(cache.ResourceEventHandlerFuncs{
		AddFunc: handleNewPodState,
		UpdateFunc: func(old, new any) {
			handleNewPodState(new)
		},
	})

	factory.Start(ctx.Done())
	<-waitC
	return nil
}

func (c *Cluster) Pods(ctx context.Context, selector string) ([]corev1.Pod, error) {
	clientConfig, err := c.impl.restConfig(ctx)
	if err != nil {
		return nil, err
	}

	client, err := kubernetes.NewForConfig(clientConfig)
	if err != nil {
		return nil, err
	}

	pods, err := client.CoreV1().Pods("").List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}

	return pods.Items, nil
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
