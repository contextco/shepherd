package main

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	service_pb "gateway/generated/service_pb"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/test/bufconn"
)

// Mock gRPC server implementation
type mockOnPremServer struct {
	service_pb.UnimplementedOnPremServer
	t *testing.T
}

func (s *mockOnPremServer) Heartbeat(ctx context.Context, req *service_pb.HeartbeatRequest) (*service_pb.HeartbeatResponse, error) {
	// Now we can use s.t for test assertions
	if req.Identity == nil {
		s.t.Error("Expected Identity in request, got nil")
	}
	return &service_pb.HeartbeatResponse{}, nil
}

// Helper to create a test gRPC server
func setupGRPCServer(t *testing.T) (*grpc.Server, *bufconn.Listener) {
	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	service_pb.RegisterOnPremServer(server, &mockOnPremServer{t: t}) // Pass t to the mock server

	go func() {
		if err := server.Serve(listener); err != nil {
			t.Errorf("Failed to serve: %v", err)
		}
	}()

	return server, listener
}

func TestHeartbeat(t *testing.T) {
	// Setup mock gRPC server
	server, listener := setupGRPCServer(t)
	defer server.Stop()

	// Set up the gateway pointing to our mock server
	ctx := context.Background()
	mux := runtime.NewServeMux()
	conn, err := grpc.DialContext(ctx, "bufnet",
		grpc.WithContextDialer(func(ctx context.Context, s string) (net.Conn, error) {
			return listener.Dial()
		}),
		grpc.WithInsecure(),
	)
	if err != nil {
		t.Fatalf("Failed to dial bufnet: %v", err)
	}
	defer conn.Close()

	err = service_pb.RegisterOnPremHandlerClient(ctx, mux, service_pb.NewOnPremClient(conn))
	if err != nil {
		t.Fatalf("Failed to register gateway: %v", err)
	}

	// Create test server
	ts := httptest.NewServer(mux)
	defer ts.Close()

	// Test cases
	tests := []struct {
		name       string
		path       string
		request    *service_pb.HeartbeatRequest
		wantStatus int
	}{
		{
			name: "valid request",
			path: "/heartbeat",
			request: &service_pb.HeartbeatRequest{
				Identity: &service_pb.Identity{
					LifecycleId: "test-id",
					Name:        "test-worker",
				},
			},
			wantStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonReq, err := json.Marshal(tt.request)
			if err != nil {
				t.Fatalf("Failed to marshal request: %v", err)
			}

			fullURL := ts.URL + tt.path
			t.Logf("Making request to: %s", fullURL)

			// Create and make the request
			req, err := http.NewRequest(http.MethodPost, fullURL, bytes.NewBuffer(jsonReq))
			if err != nil {
				t.Fatalf("Failed to create request: %v", err)
			}
			req.Header.Set("Content-Type", "application/json")

			// Make the request
			client := &http.Client{}
			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("Failed to make request: %v", err)
			}
			defer resp.Body.Close()

			// Read and log the response body
			body, err := io.ReadAll(resp.Body)
			if err != nil {
				t.Fatalf("Failed to read response body: %v", err)
			}
			t.Logf("Response Status: %d, Body: %s", resp.StatusCode, string(body))

			if resp.StatusCode != tt.wantStatus {
				t.Errorf("Expected status %d, got %d", tt.wantStatus, resp.StatusCode)
			}
		})
	}
}

func TestRun(t *testing.T) {
	// Save original env var and restore after test
	origAddr := os.Getenv("BACKEND_ADDRESS")
	defer os.Setenv("BACKEND_ADDRESS", origAddr)

	// Set test backend address
	testAddr := "localhost:50051"
	os.Setenv("BACKEND_ADDRESS", testAddr)

	// Start server in goroutine since it blocks
	errCh := make(chan error, 1)
	go func() {
		errCh <- run(false)
	}()

	// Give server time to start
	time.Sleep(100 * time.Millisecond)

	// Test server is running by making request
	resp, err := http.Get("http://localhost:8081/health")
	if err != nil {
		t.Fatalf("Failed to make request: %v", err)
	}
	defer resp.Body.Close()

	// ensure we get a 200
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}
}

func TestMainHandler(t *testing.T) {
	mux := runtime.NewServeMux()

	// Create test server
	ts := httptest.NewServer(mux)
	defer ts.Close()

	// Test basic request
	resp, err := http.Get(ts.URL)
	if err != nil {
		t.Fatalf("Failed to make request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		// We expect 404 since we haven't registered any endpoints
		t.Errorf("Expected status 404, got %d", resp.StatusCode)
	}
}
