package testcluster

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/google/uuid"
)

// Cluster represents a kind kubernetes test cluster
type Cluster struct {
	name       string
	KubeConfig *os.File
}

// New creates a new test cluster with the given name
func New(t *testing.T, ctx context.Context, name string) *Cluster {

	cluster := &Cluster{
		name: name,
	}

	_ = cluster.delete(ctx) // ignore error if cluster does not exist

	if err := cluster.create(ctx); err != nil {
		t.Fatalf("failed to create kind cluster: %v", err)
	}

	kubeConfigFile, err := cluster.writeTempKubeConfig(ctx)
	if err != nil {
		t.Fatalf("failed to write temp kubeconfig: %v", err)
	}

	cluster.KubeConfig = kubeConfigFile

	t.Cleanup(func() {
		if err := os.Remove(cluster.KubeConfig.Name()); err != nil {
			t.Fatalf("failed to remove kubeconfig file: %v", err)
		}
		if err := cluster.delete(context.WithoutCancel(ctx)); err != nil {
			t.Fatalf("failed to delete cluster: %v", err)
		}
	})

	return cluster
}

// Create creates a new kind cluster
func (c *Cluster) create(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "kind", "create", "cluster", "--name", c.name)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to create kind cluster: %w\nOutput: %s", err, output)
	}

	return nil
}

// Delete deletes the kind cluster
func (c *Cluster) delete(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "kind", "delete", "cluster", "--name", c.name)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to delete kind cluster: %w\nOutput: %s", err, output)
	}
	return nil
}

func (c *Cluster) getKubeConfig(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "kind", "get", "kubeconfig", "--name", c.name)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to get kind kubeconfig: %w\nOutput: %s", err, output)
	}
	return string(output), nil
}

func (c *Cluster) writeTempKubeConfig(ctx context.Context) (*os.File, error) {
	kubeConfig, err := c.getKubeConfig(ctx)
	if err != nil {
		return nil, err
	}

	tmpfile, err := os.CreateTemp("", uuid.New().String())
	if err != nil {
		return nil, err
	}

	if _, err := tmpfile.WriteString(kubeConfig); err != nil {
		return nil, err
	}

	return tmpfile, nil
}
