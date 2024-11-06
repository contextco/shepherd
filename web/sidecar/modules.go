package main

import (
	"context"
	"fmt"
	"net/url"
	"sidecar/gcs"
	"sidecar/repo"
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

	repoClient, err := repo.NewClient(ctx, store, &url.URL{Scheme: "http", Host: "localhost:8080"}) // TODO: Add config var for real base URL.
	if err != nil {
		return nil, fmt.Errorf("failed to create repo client: %w", err)
	}

	return &Modules{
		Store:  store,
		Server: server.New(":8080", repoClient),
	}, nil
}
