package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
)

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
		errCh <- run()
	}()

	// Give server time to start
	time.Sleep(100 * time.Millisecond)

	// Test server is running by making request
	resp, err := http.Get("http://localhost:8081/health")
	if err != nil {
		t.Fatalf("Failed to make request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		// We expect 404 since we haven't implemented any endpoints
		t.Errorf("Expected status 404, got %d", resp.StatusCode)
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
