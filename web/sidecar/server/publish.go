package server

import (
	"context"

	"sidecar/chart"
	sidecar_pb "sidecar/generated/sidecar_pb"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func (s *Server) PublishChart(ctx context.Context, req *sidecar_pb.PublishChartRequest) (*sidecar_pb.PublishChartResponse, error) {
	if len(req.GetChart().GetServices()) == 0 {
		return nil, status.Error(codes.InvalidArgument, "services are required")
	}

	chart, err := chart.NewFromProto(req.GetChart().GetName(), req.GetChart().GetVersion(), req.GetChart())
	if err != nil {
		return nil, err
	}

	if err := s.repoClient.Add(ctx, chart, req.RepositoryDirectory); err != nil {
		return nil, err
	}

	return &sidecar_pb.PublishChartResponse{}, nil
}
