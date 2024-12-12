package backend

import (
	"context"
	"crypto/x509"
	"fmt"
	"log"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"onprem/config"
	service_pb "onprem/generated/service_pb"
)

type Identity struct {
	LifecycleID string
	Name        string
}

type Client struct {
	client   service_pb.OnPremClient
	conn     *grpc.ClientConn
	identity Identity
}

func NewClient(addr string, bearerToken string, identity Identity, opts ...grpc.DialOption) (*Client, error) {
	log.Printf("Attempting to connect to gRPC server at %s", addr)
	dialOpts := []grpc.DialOption{
		grpc.WithPerRPCCredentials(&authHeader{bearerToken: bearerToken}),
	}
	if config.Development() {
		dialOpts = append(dialOpts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	}
	dialOpts = append(dialOpts, opts...)

	conn, err := grpc.NewClient(addr, dialOpts...)
	if err != nil {
		return nil, err
	}
	return &Client{
		client:   service_pb.NewOnPremClient(conn),
		conn:     conn,
		identity: identity,
	}, nil
}

func (c *Client) Heartbeat(ctx context.Context) error {
	_, err := c.client.Heartbeat(ctx, &service_pb.HeartbeatRequest{
		Identity: &service_pb.Identity{
			LifecycleId: c.identity.LifecycleID,
			Name:        c.identity.Name,
		},
	})
	return err
}

func (c *Client) Close() error {
	return c.conn.Close()
}

type authHeader struct {
	bearerToken string
}

func (a *authHeader) GetRequestMetadata(ctx context.Context, uri ...string) (map[string]string, error) {
	return map[string]string{"authorization": fmt.Sprintf("Bearer %s", a.bearerToken)}, nil
}

func (a *authHeader) RequireTransportSecurity() bool {
	return false
}

// TOOD: How does this work if the system cert pool is empty? Or doesn't exist?
func MustSystemCertPool() *x509.CertPool {
	pool, err := x509.SystemCertPool()
	if err != nil {
		return nil
	}
	return pool
}
