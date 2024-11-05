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

const indexFileName = "index.yaml"

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

	tempFile, err := os.CreateTemp("", "sidecar-repo-index")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())

	if err := indexFile.WriteFile(tempFile.Name(), 0644); err != nil {
		return fmt.Errorf("failed to write index file: %w", err)
	}

	buf, err := os.ReadFile(tempFile.Name())
	if err != nil {
		return fmt.Errorf("failed to read temp file: %w", err)
	}

	return c.store.Upload(ctx, filepath.Join(repo, indexFileName), bytes.NewReader(buf))
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

	archivePath, err := chart.Archive(tempDir)
	if err != nil {
		return nil, fmt.Errorf("failed to archive chart: %w", err)
	}

	objectName := fmt.Sprintf("%s/%s", repo, filepath.Base(archivePath))

	reader, err := os.Open(archivePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open archive: %w", err)
	}

	hash, err := provenance.DigestFile(archivePath)
	if err != nil {
		return nil, fmt.Errorf("failed to digest archive: %w", err)
	}

	if err := c.store.Upload(ctx, objectName, reader); err != nil {
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
