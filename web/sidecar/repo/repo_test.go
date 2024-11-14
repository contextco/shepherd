package repo

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"sidecar/chart"
	"sidecar/clock"
	"sidecar/testcluster"

	"github.com/google/go-cmp/cmp"
	corev1 "k8s.io/api/core/v1"
)

type fakeStore struct {
	files  map[string][]byte
	tmpDir string
}

func newFakeStore(t *testing.T) *fakeStore {
	t.Helper()

	tmpDir := t.TempDir()

	log.Printf("test %s using tmpdir: %s", t.Name(), tmpDir)

	return &fakeStore{
		tmpDir: tmpDir,
	}
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

	// filePath := filepath.Join(f.tmpDir, path)
	// if err := os.MkdirAll(filepath.Dir(filePath), 0755); err != nil {
	// 	return err
	// }
	// if err := os.WriteFile(filePath, data, 0644); err != nil {
	// 	return err
	// }
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

func (f *fakeStore) ExistsInArchive(archivePath string, path string) (bool, error) {
	archiveData, exists := f.files[archivePath]
	if !exists {
		return false, nil
	}

	tarReader, err := archiveReader(archiveData)
	if err != nil {
		return false, err
	}

	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return false, err
		}

		if header.Name == path {
			return true, nil
		}
	}

	return false, nil
}

func (f *fakeStore) VerifyWithinArchiveAgainstFixture(t *testing.T, archivePath string, path string) error {
	tarReader, err := archiveReader(f.files[archivePath])
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
	if diff := cmp.Diff(gotData, fixture); diff != "" {
		return fmt.Errorf("fixture for %s does not match: %s", path, diff)
	}
	return nil
}

func (f *fakeStore) VerifyAgainstFixture(t *testing.T, path string) error {
	data, exists := f.files[path]
	if !exists {
		return fmt.Errorf("file %s does not exist", path)
	}

	return verifyDataAgainstFixture(t, data, path)
}

func TestAdd_indexFileIsCreated(t *testing.T) {
	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	store := &fakeStore{}

	ctx := context.Background()
	chart, err := chart.NewFromParams(&chart.Params{ChartName: "test-chart", ChartVersion: "1.0.0"})
	if err != nil {
		t.Fatalf("Failed to create empty chart: %v", err)
	}

	addChartToRepo(t, ctx, store, chart, "test-repo")

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

func TestAdd_valuesFile(t *testing.T) {
	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	cases := []struct {
		name   string
		params *chart.Params
	}{
		{
			name: "values file is created",
			params: &chart.Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				ReplicaCount: 1,
				Environment: map[string]string{
					"FOO": "bar",
				},
				Image: chart.Image{
					Name: "test-image",
					Tag:  "latest",
				},
				Resources: chart.Resources{
					CPUCoresRequested:    1,
					CPUCoresLimit:        2,
					MemoryBytesRequested: 1024,
					MemoryBytesLimit:     2048,
				},
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			ctx := context.Background()

			store := newFakeStore(t)
			chart, err := chart.NewFromParams(tc.params)
			if err != nil {
				t.Fatalf("Failed to create empty chart: %v", err)
			}

			addChartToRepo(t, ctx, store, chart, "test-repo")

			// Verify values file was created
			valuesExists, err := store.ExistsInArchive("test-repo/test-chart-1.0.0.tgz", "test-chart/values.yaml")
			if err != nil {
				t.Fatalf("Failed to check values existence: %v", err)
			}
			if !valuesExists {
				t.Error("Values file was not created")
			}

			if err := store.VerifyWithinArchiveAgainstFixture(t, "test-repo/test-chart-1.0.0.tgz", "test-chart/values.yaml"); err != nil {
				t.Fatalf("Failed to verify fixtures: %v", err)
			}
		})
	}
}

func TestAdd_clientFacingValuesFile(t *testing.T) {
	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	cases := []struct {
		name   string
		params *chart.Params
	}{
		{
			name: "values file is created",
			params: &chart.Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				ReplicaCount: 1,
				Environment: map[string]string{
					"FOO": "bar",
				},
				Secrets: []chart.Secret{
					{
						Name:           "foo",
						EnvironmentKey: "FOO",
					},
					{
						Name:           "bar",
						EnvironmentKey: "BAR",
					},
				},
				Image: chart.Image{
					Name: "test-image",
					Tag:  "latest",
				},
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			ctx := context.Background()

			store := newFakeStore(t)
			chart, err := chart.NewFromParams(tc.params)
			if err != nil {
				t.Fatalf("Failed to create empty chart: %v", err)
			}

			addChartToRepo(t, ctx, store, chart, "test-repo")

			// Verify values file was created
			valuesExists, err := store.Exists(ctx, "test-repo/test-chart-1.0.0-values.yaml")
			if err != nil {
				t.Fatalf("Failed to check values existence: %v", err)
			}
			if !valuesExists {
				t.Error("Values file was not created")
			}

			if err := store.VerifyAgainstFixture(t, "test-repo/test-chart-1.0.0-values.yaml"); err != nil {
				t.Fatalf("Failed to verify fixtures: %v", err)
			}
		})
	}
}

func TestAdd_chartsAreInstallable(t *testing.T) {
	ctx := context.Background()
	cluster := testcluster.New(t, ctx, "test-cluster")

	cases := []struct {
		name   string
		params *chart.Params
	}{
		{
			name: "chart is installable",
			params: &chart.Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				ReplicaCount: 1,
				Environment: map[string]string{
					"FOO": "bar",
				},
				Secrets: []chart.Secret{
					{
						Name:           "foo",
						EnvironmentKey: "FOO",
					},
					{
						Name:           "bar",
						EnvironmentKey: "BAR",
					},
				},
				Image: chart.Image{
					Name: "nginx",
					Tag:  "alpine",
				},
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			store := newFakeStore(t)
			c, err := chart.NewFromParams(tc.params)
			if err != nil {
				t.Fatalf("Failed to create chart: %v", err)
			}

			addChartToRepo(t, ctx, store, c, "test-repo")

			loadedChart, err := chart.LoadFromArchive(&chart.ChartArchive{
				Name: "test-chart-1.0.0.tgz",
				Data: store.files["test-repo/test-chart-1.0.0.tgz"],
			}, &chart.Params{ChartName: "test-chart", ChartVersion: "1.0.0"})
			if err != nil {
				t.Fatalf("Failed to load chart from archive: %v", err)
			}

			if err := loadedChart.Install(ctx); err != nil {
				t.Fatalf("Failed to install chart: %v", err)
			}

			if err := cluster.WaitForPods(ctx, func(pod *corev1.Pod) bool {
				return strings.Contains(pod.Name, tc.params.ChartName) && pod.Status.Phase == corev1.PodRunning
			}); err != nil {
				t.Fatalf("failed to wait for pods: %v", err)
			}
		})
	}

}

func addChartToRepo(t *testing.T, ctx context.Context, store *fakeStore, chart *chart.Chart, repo string) {
	t.Helper()

	client, err := NewClient(ctx, store, &url.URL{})
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}

	if err := client.Add(ctx, chart, repo); err != nil {
		t.Fatalf("Failed to add chart: %v", err)
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
	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	store := &fakeStore{
		files: map[string][]byte{
			"test-repo/index.yaml": []byte(`apiVersion: v1
entries:
  test-chart:
    - name: test-chart
      version: 0.9.0
      urls:
        - test-chart-0.9.0.tgz
`),
		},
	}

	ctx := context.Background()
	client, err := NewClient(ctx, store, &url.URL{})
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}

	chart, err := chart.NewFromParams(&chart.Params{
		ChartName:    "test-chart",
		ChartVersion: "1.0.0",
	})
	if err != nil {
		t.Fatalf("Failed to create empty chart: %v", err)
	}

	if err := client.Add(ctx, chart, "test-repo"); err != nil {
		t.Fatalf("Failed to add chart: %v", err)
	}

	// Verify both versions exist in index
	indexData := store.files["test-repo/index.yaml"]
	if !bytes.Contains(indexData, []byte("version: 1.0.0")) || !bytes.Contains(indexData, []byte("version: 0.9.0")) {
		t.Error("Index file does not contain both versions")
	}

	store.files["test-repo/index.yaml"] = stripIndexDigests(t, indexData)

	if err := store.VerifyAgainstFixture(t, "test-repo/index.yaml"); err != nil {
		t.Fatalf("Failed to verify fixtures: %v", err)
	}
}

func archiveReader(data []byte) (*tar.Reader, error) {
	gzipReader, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, fmt.Errorf("failed to create gzip reader: %w", err)
	}

	return tar.NewReader(gzipReader), nil
}
