package chart

import (
	"context"
	"fmt"
	"sidecar/test/testcluster"
	"strings"
	"testing"

	corev1 "k8s.io/api/core/v1"
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
			chart, err := NewParentChart()
			if err != nil {
				t.Fatalf("failed to create chart: %v", err)
			}

			chart, err = chart.ApplyParams(tt.params)
			if err != nil {
				t.Fatalf("failed to apply params to chart: %v", err)
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
	cluster := testcluster.New(t, ctx, "test")
	image := Image{
		Name: "nginx",
		Tag:  "stable-alpine",
	}

	cases := []struct {
		name    string
		params  *Params
		wantErr bool
	}{
		{
			name: "valid params",
			params: &Params{
				Image: image,
				Secrets: []Secret{
					{
						Name:           "test-secret",
						EnvironmentKey: "TEST_SECRET",
					},
				},
				Services: []*Service{
					{Port: 8000},
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
			name: "without environment variables",
			params: &Params{
				ReplicaCount: 1,
				Image:        image,
				Secrets: []Secret{
					{
						Name:           "test-secret",
						EnvironmentKey: "TEST_SECRET",
					},
				},
			},
			wantErr: false,
		},
		{
			name: "without secrets",
			params: &Params{
				ReplicaCount: 1,
				Image:        image,
				Services:     []*Service{{Port: 8000}},
				Environment: Environment{
					"TEST_ENV":    "test-env",
					"ANOTHER_ENV": "another-env",
				},
			},
			wantErr: false,
		},
		{
			name: "without services",
			params: &Params{
				ReplicaCount: 1,
				Image:        image,
			},
			wantErr: false,
		},
		{
			name: "invalid replica count",
			params: &Params{
				Image:        image,
				ReplicaCount: -1,
			},
			wantErr: true,
		},
	}

	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			tt.params.ChartName = fmt.Sprintf("test-%s", strings.ReplaceAll(tt.name, " ", "-"))
			tt.params.ChartVersion = "0.0.1"
			parent, err := NewParentChart()
			if err != nil {
				t.Fatalf("failed to create parent chart: %v", err)
			}
			chart, err := parent.ApplyParams(tt.params)
			if err != nil {
				t.Fatalf("failed to create chart: %v", err)
			}

			err = chart.Install(ctx)
			if err != nil {
				if tt.wantErr {
					return
				}
				t.Fatalf("Chart.Install() error = %v, wantErr %v", err, tt.wantErr)
			} else if tt.wantErr {
				t.Fatalf("Chart.Install() error = %v, wantErr %v", err, tt.wantErr)
			}

			if err := cluster.WaitForPods(ctx, func(pod *corev1.Pod) bool {
				return strings.Contains(pod.Name, tt.params.ChartName) && pod.Status.Phase == corev1.PodRunning
			}); err != nil {
				t.Fatalf("failed to wait for pods: %v", err)
			}
		})
	}
}
