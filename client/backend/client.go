package backend

import (
	"context"
	"crypto/x509"
	"fmt"

	"google.golang.org/grpc"

	service_pb "onprem/generated/protos"
)

type Client struct {
	client service_pb.OnPremClient
	conn   *grpc.ClientConn
}

func NewClient(addr string, bearerToken string, opts ...grpc.DialOption) (*Client, error) {
	dialOpts := []grpc.DialOption{
		grpc.WithPerRPCCredentials(&authHeader{bearerToken: bearerToken}),
	}
	dialOpts = append(dialOpts, opts...)

	conn, err := grpc.NewClient(addr, dialOpts...)
	if err != nil {
		return nil, err
	}
	return &Client{client: service_pb.NewOnPremClient(conn), conn: conn}, nil
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
