package repo

import (
	"bytes"
	"context"
	"io"
	"maps"
	"os"
	"sidecar/chart"
	"slices"
	"testing"
)

type fakeStore struct {
	files map[string][]byte
}

func (f *fakeStore) Upload(_ context.Context, path string, reader io.Reader) error {
	if f.files == nil {
		f.files = make(map[string][]byte)
	}
	data, err := io.ReadAll(reader)
	if err != nil {
		return err
	}
	f.files[path] = data
	return nil
}

func (f *fakeStore) Exists(_ context.Context, path string) (bool, error) {
	_, exists := f.files[path]
	return exists, nil
}

func (f *fakeStore) ReadToTempFile(_ context.Context, path string) (*os.File, error) {
	data, exists := f.files[path]
	if !exists {
		return nil, os.ErrNotExist
	}

	tmpFile, err := os.CreateTemp("", "repo-test")
	if err != nil {
		return nil, err
	}

	if _, err := tmpFile.Write(data); err != nil {
		return nil, err
	}

	if err := tmpFile.Close(); err != nil {
		return nil, err
	}

	return tmpFile, nil
}

func TestClientAdd(t *testing.T) {
	store := &fakeStore{}

	ctx := context.Background()
	client, err := NewClient(ctx, store)
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}

	chart, err := chart.NewFromParams(&chart.Params{ChartName: "test-chart", ChartVersion: "1.0.0"})
	if err != nil {
		t.Fatalf("Failed to create empty chart: %v", err)
	}

	if err := client.Add(ctx, chart, "test-repo"); err != nil {
		t.Fatalf("Failed to add chart: %v", err)
	}

	// Verify index file was created
	indexExists, err := store.Exists(ctx, "test-repo/index.yaml")
	if err != nil {
		t.Fatalf("Failed to check index existence: %v", err)
	}
	if !indexExists {
		t.Error("Index file was not created")
	}

	// Verify chart file was uploaded
	chartPath := "test-repo/test-chart-1.0.0.tgz"
	chartExists, err := store.Exists(ctx, chartPath)
	if err != nil {
		t.Fatalf("Failed to check chart existence: %v", err)
	}
	if !chartExists {
		t.Errorf("Chart file was not uploaded, got %+v", slices.Sorted(maps.Keys(store.files)))
	}
}

func TestClientAddUpdatesExistingIndex(t *testing.T) {
	store := &fakeStore{
		files: map[string][]byte{
			"test-repo/index.yaml": []byte(`apiVersion: v1
entries:
  test-chart:
    - name: test-chart
      version: 0.9.0
`),
		},
	}

	ctx := context.Background()
	client, err := NewClient(ctx, store)
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}

	chart, err := chart.Empty("test-chart")
	if err != nil {
		t.Fatalf("Failed to create empty chart: %v", err)
	}

	if err := client.Add(ctx, chart, "test-repo"); err != nil {
		t.Fatalf("Failed to add chart: %v", err)
	}

	// Verify both versions exist in index
	indexData := store.files["test-repo/index.yaml"]
	if !bytes.Contains(indexData, []byte("version: 0.9.0")) || !bytes.Contains(indexData, []byte("version: 0.1.0")) {
		t.Error("Index file does not contain both versions")
	}
}
