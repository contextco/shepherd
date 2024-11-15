package server

import (
	"context"
	"errors"
	"sidecar/chart"
	sidecar_pb "sidecar/generated/sidecar_pb"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func (s *Server) ValidateChart(ctx context.Context, req *sidecar_pb.ValidateChartRequest) (*sidecar_pb.ValidateChartResponse, error) {
	if req.GetChart() == nil {
		return nil, errors.New("chart is required")
	}

	if len(req.GetChart().GetServices()) == 0 {
		return nil, errors.New("at least one service is required")
	}

	c, err := chart.NewFromProto(req.GetChart().GetName(), req.GetChart().GetVersion(), req.GetChart())
	if err != nil {
		return nil, err
	}

	if err := c.Validate(); err != nil && errors.Is(err, chart.ValidationError) {
		return &sidecar_pb.ValidateChartResponse{
			Valid:  false,
			Errors: []string{err.Error()},
		}, nil
	} else if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to validate chart: %s", err.Error())
	}

	return &sidecar_pb.ValidateChartResponse{
		Valid: true,
	}, nil
}
