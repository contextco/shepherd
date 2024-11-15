package testcluster

import (
	"context"
	"testing"
	"time"
)

func TestNew(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	cluster := New(t, ctx)
	if cluster == nil {
		t.Fatal("expected cluster to not be nil")
	}

	if cluster.KubeConfig == nil {
		t.Error("expected kubeconfig file to not be nil")
	}
}

func TestClusterOperations(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	cluster := &Cluster{
		name: "test-ops-cluster",
	}

	// Test create
	if err := cluster.create(ctx); err != nil {
		t.Fatalf("failed to create cluster: %v", err)
	}

	// Test getting kubeconfig
	config, err := cluster.getKubeConfig(ctx)
	if err != nil {
		t.Fatalf("failed to get kubeconfig: %v", err)
	}
	if config == "" {
		t.Error("expected non-empty kubeconfig")
	}

	// Test writing kubeconfig
	kubeConfigFile, err := cluster.writeTempKubeConfig(ctx)
	if err != nil {
		t.Fatalf("failed to write kubeconfig: %v", err)
	}
	if kubeConfigFile == nil {
		t.Error("expected kubeconfig file to not be nil")
	}
	defer kubeConfigFile.Close()

	// Test delete
	if err := cluster.delete(ctx); err != nil {
		t.Fatalf("failed to delete cluster: %v", err)
	}
}
