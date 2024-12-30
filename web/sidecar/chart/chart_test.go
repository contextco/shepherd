package chart

import (
	"testing"

	sidecar_pb "sidecar/generated/sidecar_pb"

	"github.com/google/go-cmp/cmp"
)

func TestChart_ClientFacingValuesFile(t *testing.T) {
	for _, test := range []struct {
		name string
		req  *sidecar_pb.PublishChartRequest
		want map[string]interface{}
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
				RepositoryDirectory: "test-repo",
			},
			want: map[string]interface{}{
				"test-service": map[string]interface{}{
					"ingress": map[string]interface{}{
						"scheme": "external",
						"port":   80,
						"enabled": true,
						"external": map[string]interface{}{
							"host": "TODO: Replace this with the domain name where you will host the service. Note, this field has no effect if the ingress is internal.",
						},
					},
				},
			},
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			chart, err := NewFromProto(test.req.Chart.Name, test.req.Chart.Version, test.req.Chart)
			if err != nil {
				t.Fatalf("failed to create chart: %v", err)
			}

			vs, err := chart.ClientFacingValuesFile()
			if err != nil {
				t.Fatalf("failed to get client facing values file: %v", err)
			}

			if !cmp.Equal(vs.Values, test.want) {
				t.Fatalf("got %v, want %v", vs.Values, test.want)
			}
		})
	}
}
