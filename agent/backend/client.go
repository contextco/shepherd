package backend

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/akuity/grpc-gateway-client/pkg/grpc/gateway"

	service_pb "agent/generated/service_pb"
)

type Identity struct {
	LifecycleID string
	Name        string
	VersionID   string
}

type Client struct {
	client   service_pb.OnPremGatewayClient
	identity Identity
}

func NewClient(addr string, bearerToken string, identity Identity) (*Client, error) {
	log.Printf("Attempting to connect to gRPC server at %s", addr)
	client := &http.Client{
		Transport: &defaultHeaderTransport{
			headers: map[string]string{
				"Authorization": fmt.Sprintf("Bearer %s", bearerToken),
			},
			rt: http.DefaultTransport,
		},
	}

	return &Client{
		client:   service_pb.NewOnPremGatewayClient(gateway.NewClient(addr, gateway.WithHTTPClient(client))),
		identity: identity,
	}, nil
}

func (c *Client) Apply(ctx context.Context) (*service_pb.Action, error) {
	resp, err := c.client.Apply(ctx, &service_pb.ApplyRequest{
		Identity: &service_pb.Identity{
			LifecycleId: c.identity.LifecycleID,
			Name:        c.identity.Name,
			VersionId:   c.identity.VersionID,
		},
	})
	if err != nil {
		return nil, err
	}

	return resp.Action, nil
}

func (c *Client) Heartbeat(ctx context.Context) error {
	_, err := c.client.Heartbeat(ctx, &service_pb.HeartbeatRequest{
		Identity: &service_pb.Identity{
			LifecycleId: c.identity.LifecycleID,
			Name:        c.identity.Name,
			VersionId:   c.identity.VersionID,
		},
	})
	return err
}

// custom transport that adds headers
type defaultHeaderTransport struct {
	headers map[string]string
	rt      http.RoundTripper
}

func (dht *defaultHeaderTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	for key, value := range dht.headers {
		if req.Header.Get(key) == "" { // only add if not already set
			req.Header.Set(key, value)
		}
	}
	return dht.rt.RoundTrip(req)
}
