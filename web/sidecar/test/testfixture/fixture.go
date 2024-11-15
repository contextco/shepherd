package testfixture

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sidecar/store"
	"testing"

	"github.com/google/go-cmp/cmp"
)

type Fixture struct {
	store *store.MemoryStore
}

func New(store *store.MemoryStore) *Fixture {
	return &Fixture{
		store: store,
	}
}

func verifyDataAgainstFixture(t *testing.T, gotData []byte, path string) error {
	fixturePath := filepath.Join("testdata", t.Name(), path)
	if _, err := os.Stat(fixturePath); os.IsNotExist(err) {
		if err := os.MkdirAll(filepath.Dir(fixturePath), 0755); err != nil {
			return err
		}
		if err := os.WriteFile(fixturePath, gotData, 0644); err != nil {
			return err
		}
	}

	fixture, err := os.ReadFile(fixturePath)
	if err != nil {
		return err
	}
	if diff := cmp.Diff(string(gotData), string(fixture)); diff != "" {
		return fmt.Errorf("fixture for %s does not match: %s", path, diff)
	}
	return nil
}

func (f *Fixture) Verify(t *testing.T, ctx context.Context, path string) error {
	t.Helper()

	for storePath, data := range f.store.Files {
		if storePath != path {
			continue
		}

		return verifyDataAgainstFixture(t, data, path)
	}

	return nil
}

func (f *Fixture) VerifyWithinArchive(t *testing.T, ctx context.Context, archivePath string, path string) error {
	t.Helper()

	data, err := f.store.ReadAll(ctx, archivePath)
	if err != nil {
		return fmt.Errorf("failed to read archive %s: %w", archivePath, err)
	}

	tarReader, err := archiveReader(data)
	if err != nil {
		return fmt.Errorf("failed to create archive reader: %w", err)
	}

	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		if header.Name != path {
			continue
		}

		actualData, err := io.ReadAll(tarReader)
		if err != nil {
			return fmt.Errorf("failed to read data from archive: %w", err)
		}

		if err := verifyDataAgainstFixture(t, actualData, filepath.Join(filepath.Dir(archivePath), path)); err != nil {
			return err
		}
	}

	return nil
}

func archiveReader(data []byte) (*tar.Reader, error) {
	gzipReader, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, fmt.Errorf("failed to create gzip reader: %w", err)
	}

	return tar.NewReader(gzipReader), nil
}

func Verify(t *testing.T, ctx context.Context, store *store.MemoryStore, path string) error {
	t.Helper()

	return New(store).Verify(t, ctx, path)
}

func VerifyWithinArchive(t *testing.T, ctx context.Context, store *store.MemoryStore, archivePath string, path string) error {
	t.Helper()

	return New(store).VerifyWithinArchive(t, ctx, archivePath, path)
}
