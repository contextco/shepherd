package gcs

import (
	"context"
	"fmt"
	"io"
	"os"

	"cloud.google.com/go/storage"
)

type Client struct {
	bucket string
	*storage.Client
}

func (s *Client) Upload(ctx context.Context, object string, r io.Reader) error {
	wc := s.Bucket(s.bucket).Object(object).NewWriter(ctx)

	_, err := io.Copy(wc, r)
	if err != nil {
		return fmt.Errorf("failed to copy to object: %w", err)
	}

	return wc.Close()
}

func (s *Client) Exists(ctx context.Context, object string) (bool, error) {
	_, err := s.Bucket(s.bucket).Object(object).Attrs(ctx)
	return err == nil, nil
}

func (s *Client) ReadToTempFile(ctx context.Context, object string) (*os.File, error) {
	reader, err := s.Bucket(s.bucket).Object(object).NewReader(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to read object: %w", err)
	}
	defer reader.Close()

	tempFile, err := os.CreateTemp("", "sidecar-repo")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}

	_, err = io.Copy(tempFile, reader)
	return tempFile, err
}

func NewClient(ctx context.Context, bucket string) (*Client, error) {
	client, err := storage.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to create storage client: %w", err)
	}

	return &Client{Client: client, bucket: bucket}, nil
}
