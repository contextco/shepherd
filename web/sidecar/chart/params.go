package chart

import (
	"fmt"
	"sidecar/generated/sidecar_pb"
	"sidecar/values"

	"helm.sh/helm/v3/pkg/chartutil"
)

type Params struct {
	ChartName    string
	ChartVersion string

	Image        Image
	ReplicaCount int

	Resources Resources

	Environment Environment
	Secrets     Secrets
}

type Resources struct {
	CPUCoresRequested int
	CPUCoresLimit     int

	MemoryBytesRequested int
	MemoryBytesLimit     int
}

func (r Resources) toValues() map[string]interface{} {
	return map[string]interface{}{
		"limits": map[string]interface{}{
			"cpu":    fmt.Sprintf("%dm", r.CPUCoresLimit*1000),
			"memory": fmt.Sprintf("%d", r.MemoryBytesLimit),
		},
		"requests": map[string]interface{}{
			"cpu":    fmt.Sprintf("%dm", r.CPUCoresRequested*1000),
			"memory": fmt.Sprintf("%d", r.MemoryBytesRequested),
		},
	}
}

func (p *Params) ClientFacingValuesFile() (*values.File, error) {
	return &values.File{
		Values: compactMap(map[string]interface{}{
			"secrets": p.Secrets.toValues(),
		}),
	}, nil
}

type Environment map[string]string

func (e Environment) LoadFromProto(proto *sidecar_pb.EnvironmentConfig) {
	for _, v := range proto.GetEnvironmentVariables() {
		e[v.GetName()] = v.GetValue()
	}
}

func (e Environment) toValues() map[string]interface{} {
	return withInterfaceValues(e)
}

func (p *Params) Merge(other *Params) *Params {
	return &Params{
		ChartName:    firstNonEmpty(other.ChartName, p.ChartName),
		ChartVersion: firstNonEmpty(other.ChartVersion, p.ChartVersion),
		Image:        firstNonEmpty(other.Image, p.Image),
		ReplicaCount: firstNonEmpty(other.ReplicaCount, p.ReplicaCount),
	}
}

type Secret struct {
	Name           string
	EnvironmentKey string
}

type Secrets []Secret

func (s Secrets) LoadFromProto(protos []*sidecar_pb.Secret) {
	for _, v := range protos {
		s = append(s, Secret{Name: v.GetName(), EnvironmentKey: v.GetEnvironmentKey()})
	}
}

func (s Secrets) toValues() []map[string]interface{} {
	m := make([]map[string]interface{}, len(s))
	for i, v := range s {
		m[i] = map[string]interface{}{
			"name":           v.Name,
			"environmentKey": v.EnvironmentKey,
		}
	}
	return m
}

func (s Secrets) toClientFacingValues() []map[string]interface{} {
	m := make([]map[string]interface{}, len(s))
	for i, v := range s {
		m[i] = map[string]interface{}{
			"name":           v.Name,
			"environmentKey": v.EnvironmentKey,
			"value":          "",
		}
	}
	return m
}

type Image struct {
	Name string
	Tag  string
}

func (i Image) toValues() map[string]interface{} {
	return map[string]interface{}{
		"repository": i.Name,
		"tag":        i.Tag,
	}
}

func (p *Params) toYaml() (string, error) {
	values, err := p.toValues()
	if err != nil {
		return "", fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	return chartutil.Values(values.Values).YAML()
}

func (p *Params) toValues() (*values.File, error) {
	return &values.File{
		Values: compactMap(map[string]interface{}{
			"replicaCount": p.ReplicaCount,
			"image":        p.Image.toValues(),
			"environment":  p.Environment.toValues(),
			"secrets":      p.Secrets.toValues(),
			"resources":    p.Resources.toValues(),
		}),
	}, nil
}

func NewFromParams(params *Params) (*Chart, error) {
	template, err := canonicalTemplate()
	if err != nil {
		return nil, fmt.Errorf("error getting canonical chart: %w", err)
	}

	chart, err := template.ApplyParams(params)
	if err != nil {
		return nil, fmt.Errorf("error applying params: %w", err)
	}

	return chart, nil
}

func NewFromProto(proto *sidecar_pb.ChartParams) (*Chart, error) {
	env := Environment{}
	env.LoadFromProto(proto.GetEnvironmentConfig())

	secrets := Secrets{}
	secrets.LoadFromProto(proto.GetEnvironmentConfig().GetSecrets())

	return NewFromParams(&Params{
		ChartName:    proto.GetName(),
		ChartVersion: proto.GetVersion(),
		Image: Image{
			Name: proto.GetImage().GetName(),
			Tag:  proto.GetImage().GetTag(),
		},
		Environment: env,
		Secrets:     secrets,
	})
}

func firstNonEmpty[T comparable](values ...T) T {
	var zero T
	for _, v := range values {
		if v != zero {
			return v
		}
	}
	return zero
}

func compactMap(m map[string]interface{}) map[string]interface{} {
	for k, v := range m {
		if v == nil {
			delete(m, k)
		}

		if vm, ok := v.([]map[string]interface{}); ok {
			if len(vm) == 0 {
				delete(m, k)
			} else {
				m[k] = vm
			}
		}

		if vm, ok := v.(map[string]interface{}); ok {
			if len(vm) == 0 {
				delete(m, k)
			} else {
				vm = compactMap(vm)
			}
		}
	}
	return m
}

func withInterfaceValues[T any](v map[string]T) map[string]interface{} {
	m := make(map[string]interface{}, len(v))
	for k, v := range v {
		m[k] = v
	}
	return m
}

func valueOrZero[T any](v *T) *T {
	if v == nil {
		var zero T
		return &zero
	}
	return v
}
