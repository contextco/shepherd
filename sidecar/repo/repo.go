package repo

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sidecar/chart"

	helmrepo "helm.sh/helm/v3/pkg/repo"
)

const indexFileName = "index.yaml"

type Repo struct {
	name string
}

type Client struct {
	store Store
}

func (c *Client) Add(ctx context.Context, chart *chart.Chart, repo string) error {
	if err := c.upload(ctx, chart, repo); err != nil {
		return fmt.Errorf("failed to upload chart: %w", err)
	}

	if err := c.ensureIndex(ctx, repo, chart); err != nil {
		return fmt.Errorf("failed to update index: %w", err)
	}

	return nil
}

func (c *Client) ensureIndex(ctx context.Context, repo string, chart *chart.Chart) error {
	repoExists, err := c.store.Exists(ctx, filepath.Join(repo, indexFileName))
	if err != nil {
		return fmt.Errorf("failed to check if index file exists: %w", err)
	}

	indexFile := c.createIndex(chart)
	if repoExists {
		indexFile, err = c.updateIndex(ctx, repo, chart)
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

func (c *Client) createIndex(chart *chart.Chart) *helmrepo.IndexFile {
	indexFile := helmrepo.NewIndexFile()
	indexFile.MustAdd(chart.Metadata(), chart.Name(), chart.Version(), "")
	indexFile.SortEntries()
	return indexFile
}

func (c *Client) updateIndex(ctx context.Context, repo string, chart *chart.Chart) (*helmrepo.IndexFile, error) {
	tempFile, err := c.store.ReadToTempFile(ctx, filepath.Join(repo, indexFileName))
	if err != nil {
		return nil, fmt.Errorf("failed to read index file: %w", err)
	}
	defer os.Remove(tempFile.Name())

	indexFile, err := helmrepo.LoadIndexFile(tempFile.Name())
	if err != nil {
		return nil, fmt.Errorf("failed to load index file: %w", err)
	}

	indexFile.MustAdd(chart.Metadata(), chart.Name(), chart.Version(), "")
	indexFile.SortEntries()

	return indexFile, nil
}

func (c *Client) upload(ctx context.Context, chart *chart.Chart, repo string) error {
	tempDir, err := os.MkdirTemp("", "sidecar-repo")
	if err != nil {
		return fmt.Errorf("failed to create temp dir: %w", err)
	}
	defer os.RemoveAll(tempDir)

	archivePath, err := chart.Archive(tempDir)
	if err != nil {
		return fmt.Errorf("failed to archive chart: %w", err)
	}

	objectName := fmt.Sprintf("%s/%s", repo, filepath.Base(archivePath))

	reader, err := os.Open(archivePath)
	if err != nil {
		return fmt.Errorf("failed to open archive: %w", err)
	}

	return c.store.Upload(ctx, objectName, reader)
}

func NewClient(ctx context.Context, store Store) (*Client, error) {
	return &Client{store: store}, nil
}
