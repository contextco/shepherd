package testcluster

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/google/uuid"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"
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
			t.Logf("failed to remove kubeconfig file: %v", err)
		}
		if err := cluster.delete(context.WithoutCancel(ctx)); err != nil {
			t.Logf("failed to delete cluster: %v", err)
		}
	})

	return cluster
}

func (c *Cluster) WaitForPods(ctx context.Context, matchFunc func(*corev1.Pod) bool) error {
	clientConfig, err := clientcmd.BuildConfigFromFlags("", c.KubeConfig.Name())
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
	clientConfig, err := clientcmd.BuildConfigFromFlags("", c.KubeConfig.Name())
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
