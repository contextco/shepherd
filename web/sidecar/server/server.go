package server

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"net"
	"os"
	"sidecar/chart"
	"sidecar/repo"

	sidecar_pb "sidecar/generated/sidecar_pb"

	"github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
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
	chart, err := chart.NewFromProto(req.Chart)
	if err != nil {
		return nil, err
	}

	if err := s.repoClient.Add(ctx, chart, req.RepositoryDirectory); err != nil {
		return nil, err
	}

	return &sidecar_pb.PublishChartResponse{}, nil
}

func (s *Server) Run(ctx context.Context) error {
	log.Printf("Starting server on port %s", s.port)

	// Create a new gRPC server
	grpcServer := grpc.NewServer(loggingOptions()...)

	// Register the Sidecar server
	sidecar_pb.RegisterSidecarServer(grpcServer, s)

	// Create a listener on TCP port 50051
	lis, err := net.Listen("tcp", net.JoinHostPort("localhost", s.port))
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
	log.Printf("Server started, waiting for requests.")
	<-ctx.Done()

	// Gracefully stop the gRPC server
	grpcServer.GracefulStop()

	return nil
}

func interceptorLogger(l *slog.Logger) logging.Logger {
	return logging.LoggerFunc(func(ctx context.Context, lvl logging.Level, msg string, fields ...any) {
		l.Log(ctx, slog.Level(lvl), msg, fields...)
	})
}

func loggingOptions() []grpc.ServerOption {
	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))

	opts := []logging.Option{
		logging.WithLogOnEvents(logging.StartCall, logging.FinishCall),
	}

	return []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(logging.UnaryServerInterceptor(interceptorLogger(logger), opts...)),
	}
}
