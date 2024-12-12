package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/grpclog"

	service_pb "onprem/generated/service_pb"
)

var (
	grpcServerEndpoint = os.Getenv("BACKEND_ADDRESS")
)

// LoggingMiddleware wraps an http.Handler and logs request details
type LoggingMiddleware struct {
	handler http.Handler
	logger  *log.Logger
}

func (m *LoggingMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	wrappedWriter := &responseWriter{
		ResponseWriter: w,
		status:        http.StatusOK,
	}

	startTime := time.Now()
	m.handler.ServeHTTP(wrappedWriter, r)
	duration := time.Since(startTime)
	
	m.logger.Printf("Request: method=%s path=%s remote_addr=%s status=%d duration=%v user_agent=%s",
		r.Method,
		r.URL.Path,
		r.RemoteAddr,
		wrappedWriter.status,
		duration,
		r.UserAgent(),
	)
}

type responseWriter struct {
	http.ResponseWriter
	status int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.status = code
	rw.ResponseWriter.WriteHeader(code)
}

func withLogging(handler http.Handler, logger *log.Logger) http.Handler {
	return &LoggingMiddleware{
		handler: handler,
		logger:  logger,
	}
}

func run(healthCheck bool) error {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	// Set up logging
	logger := log.New(os.Stdout, "[GATEWAY] ", log.LstdFlags|log.LUTC)

	// Create a timeout context for the initial connection
	_, connectCancel := context.WithTimeout(ctx, 5*time.Second)
	defer connectCancel()

	// Create connection options
	opts := []grpc.DialOption{
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	}

	// Connect to the gRPC server
	if healthCheck {
		logger.Printf("Attempting to connect to gRPC server at %s", grpcServerEndpoint)
		conn, err := grpc.Dial(grpcServerEndpoint, opts...)
		if err != nil {
			logger.Printf("Failed to connect to gRPC server: %v", err)
			return fmt.Errorf("failed to connect to backend: %v", err)
		}
		defer conn.Close()
		logger.Printf("Successfully connected to gRPC server")
	} else {
		logger.Printf("Skipping gRPC server connection check")
	}

	// Register gRPC server endpoint
	gwmux := runtime.NewServeMux()
	
	logger.Printf("Setting handler to gRPC server at %s", grpcServerEndpoint)
	err := service_pb.RegisterOnPremHandlerFromEndpoint(ctx, gwmux, grpcServerEndpoint, opts)
	if err != nil {
		return err
	}

	// Create a new serve mux for combining grpc-gateway and health check
	mux := http.NewServeMux()
	
	// Add health check endpoint
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	// Mount the grpc-gateway mux
	mux.Handle("/", gwmux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	loggingHandler := withLogging(mux, logger)

	logger.Printf("Starting server on port %s", port)
	return http.ListenAndServe(":"+port, loggingHandler)
}

func main() {
	flag.Parse()

	if err := run(true); err != nil {
		grpclog.Fatal(err)
	}
}
