package server

import (
	"context"
	"fmt"
	"onprem/cluster"
	"sidecar/chart"
	"sidecar/test/testcluster"
	"strings"
	"testing"

	sidecar_pb "sidecar/generated/sidecar_pb"

	"github.com/google/uuid"
)

const (
	namespace = "sidecartest"
)

func (s *Server) GenerateAndInstall(ctx context.Context, req *sidecar_pb.GenerateAndInstallRequest) (*sidecar_pb.GenerateAndInstallResponse, error) {
	c, err := testCluster(ctx)
	if err != nil {
		return nil, err
	}

	chart, err := chart.NewFromProto(req.GetChart().GetName(), req.GetChart().GetVersion(), req.GetChart())
	if err != nil {
		return nil, err
	}

	archive, err := chart.Archive()
	if err != nil {
		return nil, err
	}

	releaseName := generateReleaseName()

	if err := c.Install(ctx, archive.Data, releaseName, namespace, true); err != nil {
		return nil, fmt.Errorf("failed to install chart: %w", err)
	}

	return &sidecar_pb.GenerateAndInstallResponse{
		ReleaseName: releaseName,
	}, nil
}

func (s *Server) Uninstall(ctx context.Context, req *sidecar_pb.UninstallRequest) (*sidecar_pb.UninstallResponse, error) {
	c, err := testCluster(ctx)
	if err != nil {
		return nil, err
	}

	if err := c.Uninstall(ctx, req.ReleaseName, namespace); err != nil {
		return nil, err
	}

	return &sidecar_pb.UninstallResponse{}, nil
}

func testCluster(ctx context.Context) (*cluster.Cluster, error) {
	tc := testcluster.GKE(&testing.T{}, ctx)

	kc, err := tc.KubeConfig(ctx)
	if err != nil {
		return nil, err
	}

	c, err := cluster.FromKubeConfig(ctx, kc)
	if err != nil {
		return nil, err
	}

	return c, nil
}

func generateReleaseName() string {
	return fmt.Sprintf("sidecar-%s", strings.Split(uuid.New().String(), "-")[0])
}
