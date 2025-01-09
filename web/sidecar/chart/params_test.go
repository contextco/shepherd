package chart

import (
	"sidecar/generated/sidecar_pb"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

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
				Image: Image{
					Name:       "test-image",
					Tag:        "latest",
					PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
				},
				ReplicaCount: 3,
				Environment: Environment{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				Services: []*Service{
					{Port: 8000},
				},
				InitConfig: InitConfig{
					InitCommands: []string{"ls"},
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
					"pullPolicy": "IfNotPresent",
				},
				"replicaCount": int32(3),
				"environment": map[string]interface{}{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				"initConfig": map[string]interface{}{
					"initCommands": []map[string]interface{}{
						{
							"name":    "init-command-0",
							"command": []string{"ls"},
						},
					},
				},
				"ingress": map[string]interface{}{
					"enabled": false,
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
				"services": []map[string]any{
					{
						"port": 8000,
					},
				},
				"serviceAccount": map[string]any{
					"create": false,
				},
				"metaEnvironmentFields": map[string]interface{}{
					"enabled": false,
				},
			},
			wantErr: false,
		},
		{
			name: "empty environment",
			params: &Params{
				Image: Image{
					Name:       "test-image",
					Tag:        "latest",
					PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
				},
				ReplicaCount: 3,
				Environment:  Environment{},
				Services: []*Service{
					{Port: 8000},
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
					"pullPolicy": "IfNotPresent",
				},
				"replicaCount": int32(3),
				"initConfig":   map[string]any{},
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
				"ingress": map[string]interface{}{
					"enabled": false,
				},
				"services": []map[string]any{
					{
						"port": 8000,
					},
				},
				"serviceAccount": map[string]any{
					"create": false,
				},
				"metaEnvironmentFields": map[string]interface{}{
					"enabled": false,
				},
			},
			wantErr: false,
		},
		{
			name: "valid params with credentials",
			params: &Params{
				Image: Image{
					Name: "test-image/thing",
					Tag:  "latest",
					Credential: &ImageCredential{
						Username: "user",
						Password: "pass",
					},
					PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
				},
				ReplicaCount: 3,
				Environment: Environment{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				Services: []*Service{
					{Port: 8000},
				},
				InitConfig: InitConfig{
					InitCommands: []string{"ls"},
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
					"repository": "test-image/thing",
					"tag":        "latest",
					"pullPolicy": "IfNotPresent",
					"credential": map[string]interface{}{
						"username": "user",
						"password": "pass",
					},
				},
				"imagePullSecrets": []map[string]interface{}{
					{
						"name": "registry-credentials-test-image-thing",
					},
				},
				"replicaCount": int32(3),
				"environment": map[string]interface{}{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				"initConfig": map[string]interface{}{
					"initCommands": []map[string]interface{}{
						{
							"name":    "init-command-0",
							"command": []string{"ls"},
						},
					},
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
				"services": []map[string]any{
					{
						"port": 8000,
					},
				},
				"serviceAccount": map[string]any{
					"create": false,
				},
				"metaEnvironmentFields": map[string]interface{}{
					"enabled": false,
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
				Image: Image{
					Name:       "test-image",
					Tag:        "latest",
					PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
				},
				ReplicaCount: 3,
				Services:     []*Service{{Port: 8000}},
				Environment: Environment{
					"ENV_VAR1": "value1",
					"ENV_VAR2": "value2",
				},
				InitConfig: InitConfig{
					InitCommands: []string{"ls"},
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
  pullPolicy: IfNotPresent
  repository: test-image
  tag: latest
ingress:
  enabled: false
initConfig:
  initCommands:
  - command:
    - ls
    name: init-command-0
metaEnvironmentFields:
  enabled: false
replicaCount: 3
resources:
  limits:
    cpu: 2000m
    memory: "2048"
  requests:
    cpu: 1000m
    memory: "1024"
serviceAccount:
  create: false
services:
- port: 8000
`,
			wantErr: false,
		},
		{
			name: "empty environment",
			params: &Params{
				Image: Image{
					Name:       "test-image",
					Tag:        "latest",
					PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
				},
				ReplicaCount: 3,
				Environment:  Environment{},
				Services:     []*Service{{Port: 8000}},
				Resources: Resources{
					CPUCoresRequested:    1,
					CPUCoresLimit:        2,
					MemoryBytesRequested: 1024,
					MemoryBytesLimit:     2048,
				},
			},
			want: `image:
  pullPolicy: IfNotPresent
  repository: test-image
  tag: latest
ingress:
  enabled: false
initConfig: {}
metaEnvironmentFields:
  enabled: false
replicaCount: 3
resources:
  limits:
    cpu: 2000m
    memory: "2048"
  requests:
    cpu: 1000m
    memory: "1024"
serviceAccount:
  create: false
services:
- port: 8000
`,
			wantErr: false,
		},
		{
			name: "with image credentials",
			params: &Params{
				Image: Image{
					Name:       "test-image",
					Tag:        "latest",
					PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
					Credential: &ImageCredential{
						Username: "user",
						Password: "pass",
					},
				},
				ReplicaCount: 3,
				Services:     []*Service{{Port: 8000}},
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
  credential:
    password: pass
    username: user
  pullPolicy: IfNotPresent
  repository: test-image
  tag: latest
imagePullSecrets:
- name: registry-credentials-test-image
ingress:
  enabled: false
initConfig: {}
metaEnvironmentFields:
  enabled: false
replicaCount: 3
resources:
  limits:
    cpu: 2000m
    memory: "2048"
  requests:
    cpu: 1000m
    memory: "1024"
serviceAccount:
  create: false
services:
- port: 8000
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

func TestImage_toValues(t *testing.T) {
	tests := []struct {
		name  string
		image Image
		want  map[string]interface{}
	}{
		{
			name: "without credentials",
			image: Image{
				Name:       "test-image",
				Tag:        "latest",
				PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_ALWAYS,
			},
			want: map[string]interface{}{
				"repository": "test-image",
				"tag":        "latest",
				"pullPolicy": "Always",
			},
		},
		{
			name: "with credentials",
			image: Image{
				Name:       "test-image",
				Tag:        "latest",
				PullPolicy: sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT,
				Credential: &ImageCredential{
					Username: "user",
					Password: "pass",
				},
			},
			want: map[string]interface{}{
				"repository": "test-image",
				"tag":        "latest",
				"pullPolicy": "IfNotPresent",
				"credential": map[string]interface{}{
					"username": "user",
					"password": "pass",
				},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.image.toValues()
			if diff := cmp.Diff(got, tt.want); diff != "" {
				t.Errorf("toValues() = %v, want %v, diff = %s", got, tt.want, diff)
			}
		})
	}
}
