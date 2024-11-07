package server

import (
	"context"
	"errors"
	"sidecar/chart"
	sidecar_pb "sidecar/generated/sidecar_pb"
)

func (s *Server) ValidateChart(ctx context.Context, req *sidecar_pb.ValidateChartRequest) (*sidecar_pb.ValidateChartResponse, error) {
	if req.GetChart() == nil {
		return nil, errors.New("chart is required")
	}

	chart, err := chart.NewFromProto(req.GetChart())
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
