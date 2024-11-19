package testcluster

import (
	"context"
	_ "embed"

	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

//go:embed kubeconfigs/gke.kubeconfig
var gkeKubeConfig []byte

type gkeCluster struct {
	name string
}

func (c *Cluster) create(ctx context.Context) error {
	return nil
}

func (c *gkeCluster) restConfig(ctx context.Context) (*rest.Config, error) {
	clientConfig, err := clientcmd.RESTConfigFromKubeConfig(gkeKubeConfig)
	if err != nil {
		return nil, err
	}

	return clientConfig, nil
}
