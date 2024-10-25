package backend

import (
	"context"
	"fmt"
	"net"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"

	service_pb "onprem/generated/protos"
)

func TestNewClient(t *testing.T) {
	tests := []struct {
		name        string
		addr        string
		bearerToken string
		wantErr     bool
	}{
		{
			name:        "valid client creation",
			addr:        "localhost:8080",
			bearerToken: "test-token",
			wantErr:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := newTestClient(t, tt.addr, tt.bearerToken)
			if !tt.wantErr && client == nil {
				t.Error("NewClient() returned nil client when no error expected")
			}
			if !tt.wantErr && client == nil {
				t.Error("NewClient() returned nil client when no error expected")
			}
			if client != nil {
				client.Close()
			}
		})
	}
}

func TestAuthorizationCallOption(t *testing.T) {
	const testToken = "test-bearer-token"
	testServer := &testServer{}
	srv := grpc.NewServer(grpc.UnaryInterceptor(testServer.ensureValidToken(testToken)))
	service_pb.RegisterOnPremServer(srv, testServer)

	lis, err := net.Listen("tcp", "localhost:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}
	defer lis.Close()

	go srv.Serve(lis)
	defer srv.Stop()

	client := newTestClient(t, lis.Addr().String(), testToken)
	defer client.Close()

	// Test that auth header is properly set
	_, err = client.client.Heartbeat(context.Background(), &service_pb.HeartbeatRequest{})
	if err != nil {
		t.Fatalf("Failed to make RPC call: %v", err)
	}
}

type testServer struct {
	service_pb.UnimplementedOnPremServer
}

func (s *testServer) Heartbeat(ctx context.Context, req *service_pb.HeartbeatRequest) (*service_pb.HeartbeatResponse, error) {
	return &service_pb.HeartbeatResponse{}, nil
}

func (s *testServer) ensureValidToken(bearerToken string) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return nil, fmt.Errorf("no metadata in context")
		}
		// The keys within metadata.MD are normalized to lowercase.
		// See: https://godoc.org/google.golang.org/grpc/metadata#New
		if md["authorization"][0] != fmt.Sprintf("Bearer %s", bearerToken) {
			return nil, fmt.Errorf("invalid token")
		}
		return handler(ctx, req)
	}
}

func newTestClient(t *testing.T, addr string, bearerToken string) *Client {
	t.Helper()

	client, err := NewClient(addr, bearerToken, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}
	return client
}
