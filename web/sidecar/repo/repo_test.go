package repo

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"context"
	"fmt"
	"log"
	"net/url"
	"testing"
	"time"

	"sidecar/chart"
	"sidecar/clock"
	"sidecar/generated/sidecar_pb"
	"sidecar/store"
	"sidecar/test/testfixture"
)

func TestAdd_indexFileIsCreated(t *testing.T) {
	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	store := store.NewMemoryStore()

	ctx := context.Background()
	parent, err := chart.NewFromProto("test-chart", "1.0.0", &sidecar_pb.ChartParams{})
	if err != nil {
		t.Fatalf("Failed to create empty chart: %v", err)
	}

	addChartToRepo(t, ctx, store, parent, "test-repo")

	// Verify index file was created
	indexExists, err := store.Exists(ctx, "test-repo/index.yaml")
	if err != nil {
		t.Fatalf("Failed to check index existence: %v", err)
	}
	if !indexExists {
		t.Error("Index file was not created")
	}

	// Need to strip the digests from the index file for comparison.
	store.Files["test-repo/index.yaml"] = stripIndexDigests(t, store.Files["test-repo/index.yaml"])

	if err := testfixture.Verify(t, ctx, store, "test-repo/index.yaml"); err != nil {
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
				ChartName:    "test-service",
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

			store := store.NewMemoryStore()

			parent, err := chart.NewFromProto("test-chart", "1.0.0", &sidecar_pb.ChartParams{})
			if err != nil {
				t.Fatalf("Failed to create empty chart: %v", err)
			}

			service, err := chart.NewServiceChartFromParams(tc.params)
			if err != nil {
				t.Fatalf("Failed to create service chart: %v", err)
			}

			parent.AddService(service)

			addChartToRepo(t, ctx, store, parent, "test-repo")

			// Verify values file was created
			valuesExists, err := store.Exists(ctx, "test-repo/test-chart-1.0.0.tgz")
			if err != nil {
				t.Fatalf("Failed to check values existence: %v", err)
			}
			if !valuesExists {
				t.Error("Values file was not created")
			}

			dir := t.TempDir()
			store.Dump(dir)

			log.Println(dir)

			if err := testfixture.VerifyWithinArchive(t, ctx, store, "test-repo/test-chart-1.0.0.tgz", "test-chart/charts/test-service/values.yaml"); err != nil {
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
				ChartName:    "test-service",
				ChartVersion: "1.0.0",
				ReplicaCount: 1,
				Environment: map[string]string{
					"FOO": "bar",
				},
				Secrets: []*chart.Secret{
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

			store := store.NewMemoryStore()

			parent, err := chart.NewFromProto("test-chart", "1.0.0", &sidecar_pb.ChartParams{})
			if err != nil {
				t.Fatalf("Failed to create empty chart: %v", err)
			}

			service, err := chart.NewServiceChartFromParams(tc.params)
			if err != nil {
				t.Fatalf("Failed to create service chart: %v", err)
			}

			parent.AddService(service)

			addChartToRepo(t, ctx, store, parent, "test-repo")

			// Verify values file was created
			valuesExists, err := store.Exists(ctx, "test-repo/test-chart-1.0.0-values.yaml")
			if err != nil {
				t.Fatalf("Failed to check values existence: %v", err)
			}
			if !valuesExists {
				t.Error("Values file was not created")
			}

			if err := testfixture.Verify(t, ctx, store, "test-repo/test-chart-1.0.0-values.yaml"); err != nil {
				t.Fatalf("Failed to verify fixtures: %v", err)
			}
		})
	}
}

func addChartToRepo(t *testing.T, ctx context.Context, store *store.MemoryStore, chart *chart.ParentChart, repo string) {
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

	store := store.NewMemoryStore()
	store.Files["test-repo/index.yaml"] = []byte(`apiVersion: v1
entries:
  test-chart:
    - name: test-chart
      version: 0.9.0
      urls:
        - test-chart-0.9.0.tgz
`)

	ctx := context.Background()
	client, err := NewClient(ctx, store, &url.URL{})
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}

	parent, err := chart.NewFromProto("test-chart", "1.0.0", &sidecar_pb.ChartParams{})
	if err != nil {
		t.Fatalf("Failed to create empty chart: %v", err)
	}

	if err := client.Add(ctx, parent, "test-repo"); err != nil {
		t.Fatalf("Failed to add chart: %v", err)
	}

	// Verify both versions exist in index
	indexData := store.Files["test-repo/index.yaml"]
	if !bytes.Contains(indexData, []byte("version: 1.0.0")) || !bytes.Contains(indexData, []byte("version: 0.9.0")) {
		t.Error("Index file does not contain both versions")
	}

	store.Files["test-repo/index.yaml"] = stripIndexDigests(t, indexData)

	if err := testfixture.Verify(t, ctx, store, "test-repo/index.yaml"); err != nil {
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
