package repo

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"sidecar/chart"
	"sidecar/clock"
	"testing"
	"time"

	"github.com/google/go-cmp/cmp"
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

func (f *fakeStore) ReadAll(_ context.Context, path string) ([]byte, error) {
	data, exists := f.files[path]
	if !exists {
		return nil, os.ErrNotExist
	}

	return data, nil
}

func (f *fakeStore) VerifyAgainstFixture(t *testing.T, path string) error {
	data, exists := f.files[path]
	if !exists {
		return fmt.Errorf("file %s does not exist", path)
	}

	fixturePath := filepath.Join("testdata", t.Name(), path)
	if _, err := os.Stat(fixturePath); os.IsNotExist(err) {
		if err := os.MkdirAll(filepath.Dir(fixturePath), 0755); err != nil {
			return err
		}
		if err := os.WriteFile(fixturePath, data, 0644); err != nil {
			return err
		}
	}

	fixture, err := os.ReadFile(fixturePath)
	if err != nil {
		return err
	}
	if diff := cmp.Diff(data, fixture); diff != "" {
		return fmt.Errorf("fixture for %s does not match: %s", path, diff)
	}
	return nil
}

func TestAdd_indexFileIsCreated(t *testing.T) {
	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	store := &fakeStore{}

	ctx := context.Background()
	client, err := NewClient(ctx, store, &url.URL{})
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

	// Need to strip the digests from the index file for comparison.
	store.files["test-repo/index.yaml"] = stripIndexDigests(t, store.files["test-repo/index.yaml"])

	if err := store.VerifyAgainstFixture(t, "test-repo/index.yaml"); err != nil {
		t.Fatalf("Failed to verify fixtures: %v", err)
	}
}

func stripIndexDigests(t *testing.T, indexData []byte) []byte {
	t.Helper()

	lines := bytes.Split(indexData, []byte("\n"))
	var filteredLines [][]byte
	for _, line := range lines {
		if !bytes.Contains(line, []byte("digest")) {
			filteredLines = append(filteredLines, line)
		}
	}
	return bytes.Join(filteredLines, []byte("\n"))
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
	client, err := NewClient(ctx, store, &url.URL{})
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
