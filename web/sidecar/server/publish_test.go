package server

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"sidecar/chart"
	"sidecar/clock"
	"sidecar/repo"
	"sidecar/store"
	"sidecar/test/testcluster"
	"sidecar/test/testenv"
	"sidecar/test/testfixture"

	sidecar_pb "sidecar/generated/sidecar_pb"

	"github.com/google/uuid"
	"google.golang.org/protobuf/types/known/structpb"
	corev1 "k8s.io/api/core/v1"
)

func TestServer_Capabilities(t *testing.T) {
	_ = testenv.Load(t)

	ctx := context.Background()
	clusters := testcluster.All(t, ctx)
	capabilities, err := clusters.Capabilities(ctx)
	if err != nil {
		t.Fatalf("failed to get capabilities: %v", err)
	}

	t.Logf("capabilities: %v", capabilities)
}

func TestServerPublishChart_ExternalIngress(t *testing.T) {
	_ = testenv.Load(t)

	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	ctx := context.Background()

	tests := []struct {
		name    string
		host    string
		cluster *testcluster.Cluster
		wantErr bool
	}{
		{
			name:    "valid chart with external ingress on EKS",
			host:    "vpc.context.ai",
			cluster: testcluster.EKS(t, ctx),
		},
		{
			name:    "valid chart with external ingress on GKE",
			host:    "vpcgke.context.ai",
			cluster: testcluster.GKE(t, ctx),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			store := store.NewMemoryStore()
			repoClient, err := repo.NewClient(ctx, store, &url.URL{})
			if err != nil {
				t.Fatalf("Failed to create repo client: %v", err)
			}

			s := &Server{repoClient: repoClient}

			req := ingressRequest(t)

			_, err = s.PublishChart(ctx, req)
			if err != nil {
				if tt.wantErr {
					return
				}
				t.Fatalf("PublishChart() error = %v, wantErr %v", err, tt.wantErr)
			} else if tt.wantErr {
				t.Fatalf("PublishChart() error = %v, wantErr %v", err, tt.wantErr)
			}

			chartName := fmt.Sprintf("%s-%s", req.Chart.Name, req.Chart.Version)
			c, err := chart.LoadFromArchive(&chart.ChartArchive{
				Name: chartName,
				Data: store.Files[fmt.Sprintf("test-repo/%s.tgz", chartName)],
			})
			if err != nil {
				t.Fatalf("Failed to load chart from archive: %v", err)
			}

			releaseName := "sidecar-test-" + randomNamespace(t)
			_ = tt.cluster.Uninstall(ctx, c.Chart, releaseName)

			if err := tt.cluster.Install(ctx, c.Chart, req.Chart.Name, releaseName, map[string]any{
				"test-service": map[string]any{
					"ingress": map[string]any{
						"enabled": true,
						"scheme":  "external",
						"external": map[string]any{
							"host": tt.host,
						},
					},
				},
			}); err != nil {
				t.Fatalf("Failed to install chart: %v", err)
			}
			defer tt.cluster.Uninstall(ctx, c.Chart, releaseName)

			log.Printf("waiting for ingress %s", tt.host)
			if err := tt.cluster.WaitForIngress(ctx, tt.host); err != nil {
				t.Fatalf("failed to wait for ingress: %v", err)
			}
		})
	}
}

func waitForHost(t *testing.T, ctx context.Context, host string) error {
	t.Helper()

	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	ctx, cancel := context.WithTimeout(ctx, 5*time.Minute)
	defer cancel()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			resp, err := http.Get("https://" + host)
			if err != nil {
				t.Logf("failed to get host: %v", err)
				continue
			}
			defer resp.Body.Close()

			if resp.StatusCode == http.StatusOK {
				return nil
			}
		}
	}
}

func ingressRequest(t *testing.T) *sidecar_pb.PublishChartRequest {
	t.Helper()

	chartName := strings.ToLower(strings.ReplaceAll(t.Name(), "/", "-"))
	chartName = strings.ReplaceAll(chartName, "_", "-")
	if len(chartName) > 20 {
		chartName = chartName[:20]
	}
	chartName = strings.Trim(chartName, "-.")

	return &sidecar_pb.PublishChartRequest{
		RepositoryDirectory: "test-repo",
		Chart: &sidecar_pb.ChartParams{
			Name:    chartName,
			Version: "1.0.0",
			Services: []*sidecar_pb.ServiceParams{
				{
					Name: "test-service",
					Image: &sidecar_pb.Image{
						Name: "nginx",
						Tag:  "latest",
					},
					ReplicaCount: 1,
					Endpoints: []*sidecar_pb.Endpoint{
						{
							Port: 80,
						},
					},
					IngressConfig: &sidecar_pb.IngressParams{
						Preference: sidecar_pb.IngressPreference_PREFER_EXTERNAL,
						Port:       80,
					},
				},
			},
		},
	}
}

func TestServer_PublishChart(t *testing.T) {
	_ = testenv.Load(t)

	clock.SetFakeClockForTest(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))

	ctx := context.Background()
	clusters := testcluster.All(t, ctx)

	tests := []struct {
		name    string
		req     *sidecar_pb.PublishChartRequest
		values  map[string]any
		wantErr bool
	}{
		{
			name: "valid chart with single service",
			req: &sidecar_pb.PublishChartRequest{
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart",
					Version: "1.0.0",
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "alpine",
							},
							ReplicaCount: 1,
							InitConfig: &sidecar_pb.InitConfig{
								InitCommands: []string{"ls"},
							},
						},
					},
				},
				RepositoryDirectory: "test-repo",
			},
			wantErr: false,
		},
		{
			name: "valid chart with external dependency",
			req: &sidecar_pb.PublishChartRequest{
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart-external",
					Version: "1.0.0",
					Dependencies: []*sidecar_pb.DependencyParams{
						{
							Name:          "postgresql",
							Version:       "16.x.x",
							RepositoryUrl: "oci://registry-1.docker.io/bitnamicharts",
							ValuesAlias:   "postgresql",
							Overrides: []*sidecar_pb.OverrideParams{
								{
									Path:  "primary.persistence.size",
									Value: structpb.NewStringValue("10Gi"),
								},
							},
						},
					},
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
						},
					},
				},
				RepositoryDirectory: "test-repo",
			},
			wantErr: false,
		},
		{
			name: "valid chart with multiple services",
			req: &sidecar_pb.PublishChartRequest{
				RepositoryDirectory: "test-repo",
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart-multi",
					Version: "1.0.0",
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service-1",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
						},
						{
							Name: "test-service-2",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
							EnvironmentConfig: &sidecar_pb.EnvironmentConfig{
								EnvironmentVariables: []*sidecar_pb.EnvironmentVariable{
									{
										Name:  "TEST_ENV",
										Value: "test-env-value",
									},
								},
								Secrets: []*sidecar_pb.Secret{
									{
										Name:           "test-secret",
										EnvironmentKey: "TEST_SECRET",
									},
								},
							},
						},
					},
				},
			},
		},
		{
			name: "valid chart with stateful service",
			req: &sidecar_pb.PublishChartRequest{
				RepositoryDirectory: "test-repo",
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart-stateful",
					Version: "1.0.0",
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
							PersistentVolumeClaims: []*sidecar_pb.PersistentVolumeClaimParams{
								{
									Name:      "test-volume-claim",
									SizeBytes: 2 * 1024 * 1024 * 1024,
									Path:      "/data",
								},
							},
						},
					},
				},
			},
		},
		{
			name: "valid chart with external ingress",
			req: &sidecar_pb.PublishChartRequest{
				RepositoryDirectory: "test-repo",
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart-external-ingress",
					Version: "1.0.0",
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
							Endpoints: []*sidecar_pb.Endpoint{
								{
									Port: 80,
								},
							},
							IngressConfig: &sidecar_pb.IngressParams{
								Preference: sidecar_pb.IngressPreference_PREFER_EXTERNAL,
								Port:       80,
							},
						},
					},
				},
			},
			values: map[string]any{
				"test-service": map[string]any{
					"ingress": map[string]any{
						"enabled": true,
						"port":    80,
						"external": map[string]any{
							"host": "arbitrary-host.com",
						},
					},
				},
			},
		},
		{
			name: "valid chart with internal ingress",
			req: &sidecar_pb.PublishChartRequest{
				RepositoryDirectory: "test-repo",
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart-internal-ingress",
					Version: "1.0.0",
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
							Endpoints: []*sidecar_pb.Endpoint{
								{
									Port: 80,
								},
							},
							IngressConfig: &sidecar_pb.IngressParams{
								Preference: sidecar_pb.IngressPreference_PREFER_INTERNAL,
								Port:       80,
							},
						},
					},
				},
			},
			values: map[string]any{
				"test-service": map[string]any{
					"ingress": map[string]any{},
				},
			},
		},
		{
			name: "valid chart with meta environment fields enabled",
			req: &sidecar_pb.PublishChartRequest{
				RepositoryDirectory: "test-repo",
				Chart: &sidecar_pb.ChartParams{
					Name:    "test-chart-meta-environment-fields",
					Version: "1.0.0",
					Services: []*sidecar_pb.ServiceParams{
						{
							Name: "test-service",
							Image: &sidecar_pb.Image{
								Name: "nginx",
								Tag:  "latest",
							},
							ReplicaCount: 1,
							EnvironmentConfig: &sidecar_pb.EnvironmentConfig{
								MetaEnvironmentFieldsEnabled: true,
							},
						},
					},
				},
			},
		},
		{
			name: "missing chart",
			req: &sidecar_pb.PublishChartRequest{
				RepositoryDirectory: "test-repo",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			store := store.NewMemoryStore()
			repoClient, err := repo.NewClient(ctx, store, &url.URL{})
			if err != nil {
				t.Fatalf("Failed to create repo client: %v", err)
			}

			s := &Server{repoClient: repoClient}

			_, err = s.PublishChart(ctx, tt.req)
			if err != nil {
				if tt.wantErr {
					return
				}
				t.Fatalf("PublishChart() error = %v, wantErr %v", err, tt.wantErr)
			} else if tt.wantErr {
				t.Fatalf("PublishChart() error = %v, wantErr %v", err, tt.wantErr)
			}

			if err := verifyChartFiles(t, ctx, store, tt.req.Chart); err != nil {
				t.Errorf("Failed to verify chart files: %v", err)
			}

			chartName := fmt.Sprintf("%s-%s", tt.req.Chart.Name, tt.req.Chart.Version)
			c, err := chart.LoadFromArchive(&chart.ChartArchive{
				Name: chartName,
				Data: store.Files[fmt.Sprintf("test-repo/%s.tgz", chartName)],
			})
			if err != nil {
				t.Fatalf("Failed to load chart from archive: %v", err)
			}

			dir, err := os.MkdirTemp("", "sidecar-test")
			if err != nil {
				t.Fatalf("Failed to create temp dir: %v", err)
			}

			if err := store.Dump(dir); err != nil {
				t.Fatalf("Failed to dump store: %v", err)
			}

			t.Logf("Dumped store to %s", dir)

			releaseName := "sidecar-test-" + randomNamespace(t)

			if err := clusters.Install(ctx, c.Chart, "sidecar-test-"+randomNamespace(t), releaseName, tt.values); err != nil {
				t.Fatalf("Failed to install chart: %v", err)
			}
			defer clusters.Uninstall(ctx, c.Chart, releaseName)

			if err := waitForPods(t, ctx, clusters, tt.req.Chart); err != nil {
				t.Fatalf("failed to wait for pods: %v", err)
			}
		})
	}
}

func randomNamespace(t *testing.T) string {
	t.Helper()

	return strings.Split(uuid.New().String(), "-")[0]
}

func verifyChartFiles(t *testing.T, ctx context.Context, store *store.MemoryStore, chartParams *sidecar_pb.ChartParams) error {
	keyFiles := []string{
		"test-repo/index.yaml",
		fmt.Sprintf("test-repo/%s-%s-values.yaml", chartParams.Name, chartParams.Version),
	}
	for _, file := range keyFiles {
		if strings.Contains(file, "index.yaml") {
			store.Files[file] = stripIndexDigests(t, store.Files[file])
		}
		if err := testfixture.Verify(t, ctx, store, file); err != nil {
			return err
		}
	}

	keyArchiveFiles := []string{
		fmt.Sprintf("%s/Chart.yaml", chartParams.Name),
		fmt.Sprintf("%s/values.yaml", chartParams.Name),
	}

	for _, service := range chartParams.Services {
		keyArchiveFiles = append(keyArchiveFiles,
			[]string{
				fmt.Sprintf("%s/charts/%s/Chart.yaml", chartParams.Name, service.Name),
				fmt.Sprintf("%s/charts/%s/values.yaml", chartParams.Name, service.Name),
			}...,
		)
	}

	for _, file := range keyArchiveFiles {
		if err := testfixture.VerifyWithinArchive(t, ctx, store, fmt.Sprintf("test-repo/%s-%s.tgz", chartParams.Name, chartParams.Version), file); err != nil {
			return err
		}
	}

	return nil
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

func waitForPods(t *testing.T, ctx context.Context, clusters *testcluster.ClusterSet, chartParams *sidecar_pb.ChartParams) error {
	t.Helper()

	for _, service := range chartParams.Services {
		if err := clusters.WaitForPods(ctx, func(pod *corev1.Pod) bool {
			return strings.Contains(pod.Name, service.Name) && pod.Status.Phase == corev1.PodRunning
		}); err != nil {
			return err
		}
	}

	return nil
}
