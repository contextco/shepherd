package server

import (
	"context"
	"onprem/cluster"
	sidecar_pb "sidecar/generated/sidecar_pb"
	"sidecar/test/testcluster"
	"testing"
)

func (s *Server) Install(ctx context.Context, req *sidecar_pb.InstallRequest) (*sidecar_pb.InstallResponse, error) {
	c, err := testCluster(ctx)
	if err != nil {
		return nil, err
	}

	if err := c.Install(ctx, req.Chart); err != nil {
		return nil, err
	}

	return &sidecar_pb.InstallResponse{}, nil
}

func (s *Server) Uninstall(ctx context.Context, req *sidecar_pb.UninstallRequest) (*sidecar_pb.UninstallResponse, error) {
	c, err := testCluster(ctx)
	if err != nil {
		return nil, err
	}

	if err := c.Uninstall(ctx, req.Chart); err != nil {
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
