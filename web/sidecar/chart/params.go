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
	ReplicaCount int32

	Resources Resources

	Environment Environment
	Secrets     []*Secret

	Services []*Service
}

type Service struct {
	Port int
}

func (s *Service) Name() string {
	return fmt.Sprintf("service-%d", s.Port)
}

func (s Service) toValues() map[string]interface{} {
	return map[string]interface{}{
		"port": s.Port,
	}
}

type Resources struct {
	CPUCoresRequested int
	CPUCoresLimit     int

	MemoryBytesRequested int64
	MemoryBytesLimit     int64
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
			"secrets": sliceToClientFacingValues(p.Secrets),
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

func (s *Secret) toValues() map[string]interface{} {
	return map[string]interface{}{
		"name":           s.Name,
		"environmentKey": s.EnvironmentKey,
		"value":          "",
	}
}

func (s *Secret) toClientFacingValues() map[string]interface{} {
	return map[string]interface{}{
		"name":           s.Name,
		"environmentKey": s.EnvironmentKey,
		"value":          "",
	}
}

func (s *Secret) LoadFromProto(proto *sidecar_pb.Secret) {
	s.Name = proto.GetName()
	s.EnvironmentKey = proto.GetEnvironmentKey()
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
		Values: compactMap(map[string]any{
			"replicaCount": p.ReplicaCount,
			"image":        p.Image.toValues(),
			"environment":  p.Environment.toValues(),
			"secrets":      sliceToValues(p.Secrets),
			"resources":    p.Resources.toValues(),
			"ingress": map[string]any{
				"enabled": false,
			},
			"services": sliceToValues(p.Services),
			"serviceAccount": map[string]any{
				"create": false,
			},
		}),
	}, nil
}

func NewServiceChartFromParams(params *Params) (*Chart, error) {
	c, err := NewServiceChart()
	if err != nil {
		return nil, fmt.Errorf("error getting service chart: %w", err)
	}

	return c.ApplyParams(params)
}

func NewFromProto(name, version string, proto *sidecar_pb.ServiceParams) (*Chart, error) {
	env := Environment{}
	env.LoadFromProto(proto.GetEnvironmentConfig())

	secrets := []*Secret{}
	for _, v := range proto.GetEnvironmentConfig().GetSecrets() {
		s := &Secret{}
		s.LoadFromProto(v)
		secrets = append(secrets, s)
	}

	services := []*Service{}
	for _, v := range proto.GetEndpoints() {
		s := Service{}
		s.Port = int(v.GetPort())
		services = append(services, &s)
	}

	return NewServiceChartFromParams(&Params{
		ChartName:    name,
		ChartVersion: version,
		ReplicaCount: proto.GetReplicaCount(),
		Image: Image{
			Name: proto.GetImage().GetName(),
			Tag:  proto.GetImage().GetTag(),
		},
		Resources: Resources{
			CPUCoresRequested:    int(proto.GetResources().GetCpuCoresRequested()),
			CPUCoresLimit:        int(proto.GetResources().GetCpuCoresLimit()),
			MemoryBytesRequested: proto.GetResources().GetMemoryBytesRequested(),
			MemoryBytesLimit:     proto.GetResources().GetMemoryBytesLimit(),
		},
		Environment: env,
		Secrets:     secrets,
		Services:    services,
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

type valuable interface {
	toValues() map[string]interface{}
}

type clientFacingValuable interface {
	toClientFacingValues() map[string]interface{}
}

func sliceToValues[T valuable](s []T) []map[string]interface{} {
	m := make([]map[string]interface{}, len(s))
	for i, v := range s {
		m[i] = v.toValues()
	}
	return m
}

func sliceToClientFacingValues[T clientFacingValuable](s []T) []map[string]interface{} {
	m := make([]map[string]interface{}, len(s))
	for i, v := range s {
		m[i] = v.toClientFacingValues()
	}
	return m
}
