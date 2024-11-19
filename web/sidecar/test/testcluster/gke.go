package testcluster

import (
	"context"
	_ "embed"

	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"

	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp" // register GCP auth provider
)

//go:embed kubeconfigs/gke.kubeconfig
var gkeKubeConfig []byte

type gkeCluster struct {
	name string
}

func (c *gkeCluster) create(ctx context.Context) error {
	return nil
}

func (c *gkeCluster) delete(ctx context.Context) error {
	return nil
}

func (c *gkeCluster) getKubeConfig(ctx context.Context) ([]byte, error) {
	return gkeKubeConfig, nil
}

func (c *gkeCluster) isReusable() bool {
	return true
}

func (c *gkeCluster) restConfig(ctx context.Context) (*rest.Config, error) {
	clientConfig, err := clientcmd.RESTConfigFromKubeConfig(gkeKubeConfig)
	if err != nil {
		return nil, err
	}

	return clientConfig, nil
}
