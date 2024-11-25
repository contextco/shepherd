package testcluster

import (
	"context"
	"testing"
	"time"
)

func TestNew(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	cluster := New(t, ctx, &kindCluster{name: "test-new-cluster"})
	if cluster == nil {
		t.Fatal("expected cluster to not be nil")
	}

}

func TestClusterOperations(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	cluster := &Cluster{
		impl: &kindCluster{name: "test-ops-cluster"},
	}

	// Test create
	if err := cluster.impl.create(ctx); err != nil {
		t.Fatalf("failed to create cluster: %v", err)
	}

	// Test delete
	if err := cluster.impl.delete(ctx); err != nil {
		t.Fatalf("failed to delete cluster: %v", err)
	}
}
