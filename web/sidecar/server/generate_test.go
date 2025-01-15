package server

import (
	"context"
	"testing"

	sidecar_pb "sidecar/generated/sidecar_pb"
)

func TestGenerateChart(t *testing.T) {

	for _, test := range []struct {
		name  string
		chart *sidecar_pb.ChartParams
	}{
		{
			name: "test", chart: &sidecar_pb.ChartParams{
				Name:    "test",
				Version: "1.0.0",
				Services: []*sidecar_pb.ServiceParams{
					{
						Name:         "test",
						ReplicaCount: 1,
						Image: &sidecar_pb.Image{
							Name:       "test-image",
							Tag:        "latest",
							PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_ALWAYS,
						},
						Resources: &sidecar_pb.Resources{
							CpuCoresRequested:    1,
							CpuCoresLimit:        2,
							MemoryBytesRequested: 1024 * 1024 * 1024,
							MemoryBytesLimit:     2 * 1024 * 1024 * 1024,
						},
						EnvironmentConfig: &sidecar_pb.EnvironmentConfig{
							EnvironmentVariables: []*sidecar_pb.EnvironmentVariable{
								{
									Name:  "TEST_ENV",
									Value: "test-value",
								},
							},
							Secrets: []*sidecar_pb.Secret{
								{
									Name:           "test-secret",
									EnvironmentKey: "TEST_SECRET",
								},
							},
						},
						Endpoints: []*sidecar_pb.Endpoint{
							{
								Port: 8080,
							},
						},
						InitConfig: &sidecar_pb.InitConfig{
							InitCommands: []string{
								"echo 'init'",
							},
						},
						PersistentVolumeClaims: []*sidecar_pb.PersistentVolumeClaimParams{
							{
								Name:      "test-pvc",
								SizeBytes: 1024 * 1024 * 1024,
								Path:      "/data",
							},
						},
						IngressConfig: &sidecar_pb.IngressParams{
							Preference: sidecar_pb.IngressPreference_PREFER_EXTERNAL,
							Port:       8080,
						},
					},
				},
			},
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			req := &sidecar_pb.GenerateChartRequest{
				Chart: test.chart,
			}

			s := &Server{}

			resp, err := s.GenerateChart(context.Background(), req)
			if err != nil {
				t.Fatalf("failed to generate chart: %v", err)
			}

			if len(resp.GetChart()) == 0 {
				t.Fatalf("expected chart to be generated, got empty response")
			}
		})
	}
}
