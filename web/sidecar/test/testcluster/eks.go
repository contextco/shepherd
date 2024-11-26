package testcluster

import (
	"context"
	"encoding/base64"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/clientcmd/api"
)

const (
	eksClusterName = "shepherd-cluster"
)

type eksCluster struct {
	name string
}

func (c *eksCluster) isReusable() bool {
	return true
}

func (c *eksCluster) create(ctx context.Context) error {
	return nil
}

func (c *eksCluster) delete(ctx context.Context) error {
	return nil
}

func (c *eksCluster) source() string {
	return "eks"
}

func (c *eksCluster) getKubeConfig(ctx context.Context) ([]byte, error) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithCredentialsProvider(
		credentials.NewStaticCredentialsProvider(os.Getenv("AWS_ACCESS_KEY_ID"), os.Getenv("AWS_SECRET_ACCESS_KEY"), ""),
	))
	if err != nil {
		return nil, fmt.Errorf("unable to load AWS config: %w", err)
	}

	svc := eks.NewFromConfig(cfg)

	input := &eks.DescribeClusterInput{
		Name: aws.String(eksClusterName),
	}
	result, err := svc.DescribeCluster(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe cluster: %w", err)
	}

	cluster := result.Cluster

	base64CA, err := base64.StdEncoding.DecodeString(string(*cluster.CertificateAuthority.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to decode certificate authority: %w", err)
	}

	// Create kubeconfig structure
	config := api.Config{
		APIVersion: "v1",
		Kind:       "Config",
		Clusters: map[string]*api.Cluster{
			eksClusterName: {
				Server:                   *cluster.Endpoint,
				CertificateAuthorityData: base64CA,
			},
		},
		Contexts: map[string]*api.Context{
			eksClusterName: {
				Cluster:  eksClusterName,
				AuthInfo: eksClusterName,
			},
		},
		CurrentContext: eksClusterName,
		AuthInfos: map[string]*api.AuthInfo{
			eksClusterName: {
				Exec: &api.ExecConfig{
					APIVersion: "client.authentication.k8s.io/v1beta1",
					Command:    "aws",
					Args: []string{
						"eks",
						"get-token",
						"--cluster-name",
						eksClusterName,
					},
				},
			},
		},
	}

	return clientcmd.Write(config)
}

func (c *eksCluster) restConfig(ctx context.Context) (*rest.Config, error) {
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
