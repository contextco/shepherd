package chart

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

func TestMerge(t *testing.T) {
	tests := []struct {
		name     string
		base     *Params
		override *Params
		want     *Params
	}{
		{
			name: "empty override",
			base: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "base-image",
					Tag:  "base-tag",
				},
				ReplicaCount: 1,
			},
			override: &Params{},
			want: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "base-image",
					Tag:  "base-tag",
				},
				ReplicaCount: 1,
			},
		},
		{
			name: "full override",
			base: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "base-image",
					Tag:  "base-tag",
				},
				ReplicaCount: 1,
			},
			override: &Params{
				ChartName:    "override-chart",
				ChartVersion: "2.0.0",
				Image: Image{
					Name: "override-image",
					Tag:  "override-tag",
				},
				ReplicaCount: 2,
			},
			want: &Params{
				ChartName:    "override-chart",
				ChartVersion: "2.0.0",
				Image: Image{
					Name: "override-image",
					Tag:  "override-tag",
				},
				ReplicaCount: 2,
			},
		},
		{
			name: "partial override",
			base: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "base-image",
					Tag:  "base-tag",
				},
				ReplicaCount: 1,
			},
			override: &Params{
				ChartVersion: "2.0.0",
				ReplicaCount: 2,
			},
			want: &Params{
				ChartName:    "base-chart",
				ChartVersion: "2.0.0",
				Image: Image{
					Name: "base-image",
					Tag:  "base-tag",
				},
				ReplicaCount: 2,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.base.Merge(tt.override)
			if got.ChartName != tt.want.ChartName {
				t.Errorf("ChartName = %v, want %v", got.ChartName, tt.want.ChartName)
			}
			if got.ChartVersion != tt.want.ChartVersion {
				t.Errorf("ChartVersion = %v, want %v", got.ChartVersion, tt.want.ChartVersion)
			}
			if got.Image != tt.want.Image {
				t.Errorf("Image = %v, want %v", got.Image, tt.want.Image)
			}
			if got.ReplicaCount != tt.want.ReplicaCount {
				t.Errorf("ReplicaCount = %v, want %v", got.ReplicaCount, tt.want.ReplicaCount)
			}
		})
	}
}

func TestParams_toValues(t *testing.T) {
	tests := []struct {
		name    string
		params  *Params
		want    map[string]interface{}
		wantErr bool
	}{
		{
			name: "valid params",
			params: &Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "test-image",
					Tag:  "latest",
				},
				ReplicaCount: 3,
				Environment: Environment{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				Resources: Resources{
					CPUCoresRequested:    1,
					CPUCoresLimit:        2,
					MemoryBytesRequested: 1024,
					MemoryBytesLimit:     2048,
				},
			},
			want: map[string]interface{}{
				"image": map[string]interface{}{
					"repository": "test-image",
					"tag":        "latest",
				},
				"replicaCount": 3,
				"environment": map[string]interface{}{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				"resources": map[string]interface{}{
					"limits": map[string]interface{}{
						"cpu":    "2000m",
						"memory": "2048",
					},
					"requests": map[string]interface{}{
						"cpu":    "1000m",
						"memory": "1024",
					},
				},
				"ingress": map[string]any{
					"enabled": false,
				},
				"service": map[string]any{
					"type": "ClusterIP",
					"port": 8000,
				},
				"serviceAccount": map[string]any{
					"create": false,
				},
			},
			wantErr: false,
		},
		{
			name: "empty environment",
			params: &Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "test-image",
					Tag:  "latest",
				},
				ReplicaCount: 3,
				Environment:  Environment{},
				Resources: Resources{
					CPUCoresRequested:    1,
					CPUCoresLimit:        2,
					MemoryBytesRequested: 1024,
					MemoryBytesLimit:     2048,
				},
			},
			want: map[string]interface{}{
				"image": map[string]interface{}{
					"repository": "test-image",
					"tag":        "latest",
				},
				"replicaCount": 3,
				"resources": map[string]interface{}{
					"limits": map[string]interface{}{
						"cpu":    "2000m",
						"memory": "2048",
					},
					"requests": map[string]interface{}{
						"cpu":    "1000m",
						"memory": "1024",
					},
				},
				"ingress": map[string]any{
					"enabled": false,
				},
				"service": map[string]any{
					"type": "ClusterIP",
					"port": 8000,
				},
				"serviceAccount": map[string]any{
					"create": false,
				},
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tt.params.toValues()
			if (err != nil) != tt.wantErr {
				t.Errorf("toValues() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if diff := cmp.Diff(got.Values, tt.want, cmpopts.SortMaps(func(a, b string) bool { return a < b })); diff != "" {
				t.Errorf("toValues() = %v, want %v, diff = %s", got, tt.want, diff)
			}
		})
	}
}

func TestParams_toYaml(t *testing.T) {
	tests := []struct {
		name    string
		params  *Params
		want    string
		wantErr bool
	}{
		{
			name: "valid params",
			params: &Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "test-image",
					Tag:  "latest",
				},
				ReplicaCount: 3,
				Environment: Environment{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				Resources: Resources{
					CPUCoresRequested:    1,
					CPUCoresLimit:        2,
					MemoryBytesRequested: 1024,
					MemoryBytesLimit:     2048,
				},
			},
			want: `environment:
  ENV_VAR1: value1
  ENV_VAR2: value2
image:
  repository: test-image
  tag: latest
ingress:
  enabled: false
replicaCount: 3
resources:
  limits:
    cpu: 2000m
    memory: "2048"
  requests:
    cpu: 1000m
    memory: "1024"
service:
  port: 8000
  type: ClusterIP
serviceAccount:
  create: false
`,
			wantErr: false,
		},
		{
			name: "empty environment",
			params: &Params{
				ChartName:    "test-chart",
				ChartVersion: "1.0.0",
				Image: Image{
					Name: "test-image",
					Tag:  "latest",
				},
				ReplicaCount: 3,
				Environment:  Environment{},
				Resources: Resources{
					CPUCoresRequested:    1,
					CPUCoresLimit:        2,
					MemoryBytesRequested: 1024,
					MemoryBytesLimit:     2048,
				},
			},
			want: `image:
  repository: test-image
  tag: latest
ingress:
  enabled: false
replicaCount: 3
resources:
  limits:
    cpu: 2000m
    memory: "2048"
  requests:
    cpu: 1000m
    memory: "1024"
service:
  port: 8000
  type: ClusterIP
serviceAccount:
  create: false
`,
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tt.params.toYaml()
			if (err != nil) != tt.wantErr {
				t.Errorf("toYaml() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if diff := cmp.Diff(got, tt.want); diff != "" {
				t.Errorf("toYaml() = %v, want %v, diff = %s", got, tt.want, diff)
			}
		})
	}
}
