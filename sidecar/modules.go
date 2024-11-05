package main

import (
	"context"
	"fmt"
	"sidecar/gcs"
	"sidecar/server"
)

type Modules struct {
	Store  *gcs.Client
	Server *server.Server
}

func ModulesFromEnv(ctx context.Context) (*Modules, error) {
	store, err := gcs.NewClient(ctx, "onprem-ctx")
	if err != nil {
		return nil, fmt.Errorf("failed to create store: %w", err)
	}

	return &Modules{
		Store:  store,
		Server: server.New(),
	}, nil
}
