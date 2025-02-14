package repo

import (
	"bytes"
	"context"
	"fmt"
	"net/url"
	"path/filepath"
	"sidecar/chart"
	"strings"

	"helm.sh/helm/v3/pkg/provenance"
)

const (
	indexFileName  = "index.yaml"
	valuesFileName = "values.yaml"
)

type Client struct {
	baseURL *url.URL
	store   RepoStore
}

func (c *Client) Add(ctx context.Context, chart *chart.ParentChart, repo string) error {
	chartArchive, err := c.upload(ctx, chart, repo)
	if err != nil {
		return fmt.Errorf("failed to upload chart: %w", err)
	}

	if err := c.ensureIndex(ctx, repo, chart, chartArchive); err != nil {
		return fmt.Errorf("failed to update index: %w", err)
	}

	if err := c.ensureClientFacingValuesFile(ctx, repo, chartArchive.objectName, chart); err != nil {
		return fmt.Errorf("failed to ensure client facing values file: %w", err)
	}

	return nil
}

func (c *Client) ensureClientFacingValuesFile(ctx context.Context, repo string, objectName string, chart *chart.ParentChart) error {
	valuesFile, err := chart.ClientFacingValuesFile()
	if err != nil {
		return fmt.Errorf("failed to get client facing values file: %w", err)
	}

	valuesFileBytes, err := valuesFile.Bytes()
	if err != nil {
		return fmt.Errorf("failed to get values file bytes: %w", err)
	}

	filename := fmt.Sprintf("%s-%s", strings.TrimSuffix(filepath.Base(objectName), filepath.Ext(objectName)), valuesFileName)

	if err := c.store.Upload(ctx, filepath.Join(repo, filename), bytes.NewReader(valuesFileBytes)); err != nil {
		return fmt.Errorf("failed to upload values file: %w", err)
	}

	return nil
}

func (c *Client) ensureIndex(ctx context.Context, repo string, chart *chart.ParentChart, archive *ChartArchive) error {
	repoExists, err := c.store.Exists(ctx, filepath.Join(repo, indexFileName))
	if err != nil {
		return fmt.Errorf("failed to check if index file exists: %w", err)
	}

	indexFile := newIndexFile()
	if repoExists {
		indexFile, err = c.loadIndexFile(ctx, repo)
		if err != nil {
			return fmt.Errorf("failed to load index file: %w", err)
		}
	}

	indexFile.Add(chart.Chart, archive)

	indexFileBytes, err := indexFile.Bytes()
	if err != nil {
		return fmt.Errorf("failed to get index file bytes: %w", err)
	}

	return c.store.Upload(ctx, filepath.Join(repo, indexFileName), bytes.NewReader(indexFileBytes))
}

func (c *Client) loadIndexFile(ctx context.Context, repo string) (*indexFile, error) {
	buf, err := c.store.ReadAll(ctx, filepath.Join(repo, indexFileName))
	if err != nil {
		return nil, fmt.Errorf("failed to read index file: %w", err)
	}

	indexFile, err := newIndexFileFromBytes(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to load index file: %w", err)
	}

	return indexFile, nil
}

func (c *Client) upload(ctx context.Context, chart *chart.ParentChart, repo string) (*ChartArchive, error) {
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

func NewClient(ctx context.Context, store RepoStore, baseURL *url.URL) (*Client, error) {
	return &Client{baseURL: baseURL, store: store}, nil
}

type ChartArchive struct {
	hash       string
	objectName string
}
