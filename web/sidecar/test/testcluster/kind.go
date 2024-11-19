package testcluster

import (
	"context"
	"fmt"
	"os/exec"

	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

type kindCluster struct {
	name string
}

func (c *kindCluster) create(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "kind", "create", "cluster", "--name", c.name)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to create kind cluster: %w\nOutput: %s", err, output)
	}
	return nil
}

func (c *kindCluster) delete(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "kind", "delete", "cluster", "--name", c.name)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to delete kind cluster: %w\nOutput: %s", err, output)
	}
	return nil
}

func (c *kindCluster) getKubeConfig(ctx context.Context) ([]byte, error) {
	cmd := exec.CommandContext(ctx, "kind", "get", "kubeconfig", "--name", c.name)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("failed to get kind kubeconfig: %w\nOutput: %s", err, output)
	}
	return output, nil
}

func (c *kindCluster) restConfig(ctx context.Context) (*rest.Config, error) {
	kubeConfig, err := c.getKubeConfig(ctx)
	if err != nil {
		return nil, err
	}

	clientConfig, err := clientcmd.RESTConfigFromKubeConfig(kubeConfig)
	if err != nil {
		return nil, err
	}

	return clientConfig, nil
}
