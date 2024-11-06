package server

import (
	"context"
	"sidecar/chart"
	sidecar_pb "sidecar/generated/sidecar_pb"
)

func (s *Server) ValidateChart(ctx context.Context, req *sidecar_pb.ValidateChartRequest) (*sidecar_pb.ValidateChartResponse, error) {
	chart, err := chart.NewFromProto(req.Chart)
	if err != nil {
		return nil, err
	}

	if err := chart.Validate(); err != nil {
		return nil, err
	}

	return &sidecar_pb.ValidateChartResponse{
		Valid: true,
	}, nil
}
