package backend

import (
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	service_pb "onprem/generated/protos"
)

type Client struct {
	client service_pb.OnPremClient
	conn   *grpc.ClientConn
}

func NewClient(addr string) (*Client, error) {
	conn, err := grpc.NewClient(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, err
	}
	return &Client{client: service_pb.NewOnPremClient(conn), conn: conn}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}
