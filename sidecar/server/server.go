package server

import (
	"context"
	"fmt"
	"net"
	"sidecar/chart"
	"sidecar/repo"

	sidecar_pb "sidecar/generated/sidecar_pb"

	"google.golang.org/grpc"
)

type Server struct {
	sidecar_pb.UnimplementedSidecarServer
	port       string
	repoClient *repo.Client
}

func New(port string, repoClient *repo.Client) *Server {
	return &Server{
		port:       port,
		repoClient: repoClient,
	}
}

func (s *Server) PublishChart(ctx context.Context, req *sidecar_pb.PublishChartRequest) (*sidecar_pb.PublishChartResponse, error) {
	params := &chart.Params{
		ChartName:    req.Chart.Name,
		ChartVersion: req.Chart.Version,
		Container: chart.Container{
			Image: req.Chart.Container.Name,
			Tag:   req.Chart.Container.Tag,
		},
	}

	chart, err := chart.NewFromParams(params)
	if err != nil {
		return nil, err
	}

	if err := s.repoClient.Add(ctx, chart, req.RepositoryDirectory); err != nil {
		return nil, err
	}

	return &sidecar_pb.PublishChartResponse{}, nil
}

func (s *Server) Run(ctx context.Context) error {
	// Create a new gRPC server
	grpcServer := grpc.NewServer()

	// Register the Sidecar server
	sidecar_pb.RegisterSidecarServer(grpcServer, s)

	// Create a listener on TCP port 50051
	lis, err := net.Listen("tcp", s.port)
	if err != nil {
		return fmt.Errorf("failed to listen: %v", err)
	}

	// Start the gRPC server
	go func() {
		if err := grpcServer.Serve(lis); err != nil {
			fmt.Printf("failed to serve: %v\n", err)
		}
	}()

	// Wait for the context to be done
	<-ctx.Done()

	// Gracefully stop the gRPC server
	grpcServer.GracefulStop()

	return nil
}
