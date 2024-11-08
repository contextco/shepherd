package chart

import (
	"context"
	"sidecar/testcluster"
	"testing"
)

func TestChartValidate(t *testing.T) {
	tests := []struct {
		name    string
		params  *Params
		wantErr bool
	}{
		{
			name: "valid params",
			params: &Params{
				Image: Image{
					Name: "nginx",
					Tag:  "latest",
				},
				ReplicaCount: 1,
			},
			wantErr: false,
		},
		{
			name: "invalid replica count",
			params: &Params{
				ReplicaCount: -1,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chart, err := NewFromParams(tt.params)
			if err != nil {
				t.Fatalf("failed to create chart: %v", err)
			}

			err = chart.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Chart.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestChartInstall(t *testing.T) {
	ctx := context.Background()
	_ = testcluster.New(t, ctx, "test")

	cases := []struct {
		name    string
		params  *Params
		wantErr bool
	}{
		{
			name: "valid params",
			params: &Params{
				ChartName:    "test",
				ChartVersion: "0.0.1",
				Image: Image{
					Name: "nginx",
					Tag:  "latest",
				},
				Secrets: Secrets{
					{
						Name:           "test-secret",
						EnvironmentKey: "TEST_SECRET",
					},
				},
				Environment: Environment{
					"TEST_ENV":    "test-env",
					"ANOTHER_ENV": "another-env",
				},
				ReplicaCount: 1,
			},
			wantErr: false,
		},
		{
			name: "invalid replica count",
			params: &Params{
				ReplicaCount: -1,
			},
			wantErr: true,
		},
	}

	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			chart, err := NewFromParams(tt.params)
			if err != nil {
				t.Fatalf("failed to create chart: %v", err)
			}

			err = chart.Install(ctx)
			if (err != nil) != tt.wantErr {
				t.Errorf("Chart.Install() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
