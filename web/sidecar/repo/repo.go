package repo

import (
	"bytes"
	"context"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"sidecar/chart"

	"helm.sh/helm/v3/pkg/provenance"
)

const (
	indexFileName  = "index.yaml"
	valuesFileName = "values.yaml"
)

type Client struct {
	baseURL *url.URL
	store   Store
}

func (c *Client) Add(ctx context.Context, chart *chart.Chart, repo string) error {
	objectName, err := c.upload(ctx, chart, repo)
	if err != nil {
		return fmt.Errorf("failed to upload chart: %w", err)
	}

	if err := c.ensureIndex(ctx, repo, chart, objectName); err != nil {
		return fmt.Errorf("failed to update index: %w", err)
	}

	if err := c.ensureClientFacingValuesFile(ctx, repo, chart); err != nil {
		return fmt.Errorf("failed to ensure client facing values file: %w", err)
	}

	return nil
}

func (c *Client) ensureClientFacingValuesFile(ctx context.Context, repo string, chart *chart.Chart) error {
	valuesFile, err := chart.ClientFacingValuesFile()
	if err != nil {
		return fmt.Errorf("failed to get client facing values file: %w", err)
	}

	valuesFileBytes, err := valuesFile.Bytes()
	if err != nil {
		return fmt.Errorf("failed to get values file bytes: %w", err)
	}

	if err := c.store.Upload(ctx, filepath.Join(repo, valuesFileName), bytes.NewReader(valuesFileBytes)); err != nil {
		return fmt.Errorf("failed to upload values file: %w", err)
	}

	return nil
}

func (c *Client) ensureIndex(ctx context.Context, repo string, chart *chart.Chart, archive *ChartArchive) error {
	repoExists, err := c.store.Exists(ctx, filepath.Join(repo, indexFileName))
	if err != nil {
		return fmt.Errorf("failed to check if index file exists: %w", err)
	}

	indexFile := newIndexFile(chart, archive)
	if repoExists {
		indexFile, err = c.updateIndex(ctx, repo, chart, archive)
		if err != nil {
			return fmt.Errorf("failed to update index: %w", err)
		}
	}

	indexFileBytes, err := indexFile.Bytes()
	if err != nil {
		return fmt.Errorf("failed to get index file bytes: %w", err)
	}

	return c.store.Upload(ctx, filepath.Join(repo, indexFileName), bytes.NewReader(indexFileBytes))
}

func (c *Client) updateIndex(ctx context.Context, repo string, chart *chart.Chart, archive *ChartArchive) (*indexFile, error) {
	buf, err := c.store.ReadAll(ctx, filepath.Join(repo, indexFileName))
	if err != nil {
		return nil, fmt.Errorf("failed to read index file: %w", err)
	}

	indexFile, err := newIndexFileFromBytes(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to load index file: %w", err)
	}

	indexFile.MustAdd(chart.Metadata(), chart.Name(), archive.objectName, archive.hash)
	indexFile.SortEntries()

	return indexFile, nil
}

func (c *Client) upload(ctx context.Context, chart *chart.Chart, repo string) (*ChartArchive, error) {
	tempDir, err := os.MkdirTemp("", "sidecar-repo")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp dir: %w", err)
	}
	defer os.RemoveAll(tempDir)

	archive, err := chart.Archive()
	if err != nil {
		return nil, fmt.Errorf("failed to archive chart: %w", err)
	}

	hash, err := provenance.Digest(bytes.NewReader(archive.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to digest archive: %w", err)
	}

	objectName := filepath.Join(repo, archive.Name)
	if err := c.store.Upload(ctx, objectName, bytes.NewReader(archive.Data)); err != nil {
		return nil, fmt.Errorf("failed to upload archive: %w", err)
	}

	return &ChartArchive{
		hash:       hash,
		objectName: objectName,
	}, nil
}

func NewClient(ctx context.Context, store Store, baseURL *url.URL) (*Client, error) {
	return &Client{baseURL: baseURL, store: store}, nil
}

type ChartArchive struct {
	hash       string
	objectName string
}
