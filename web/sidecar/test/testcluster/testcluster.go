package testcluster

import (
	"context"
	"strings"
	"testing"

	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/cache"

	corev1 "k8s.io/api/core/v1"
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
