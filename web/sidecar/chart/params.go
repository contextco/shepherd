package chart

import (
	"fmt"
	"sidecar/generated/sidecar_pb"
	"sidecar/values"
	"strings"

	"helm.sh/helm/v3/pkg/chartutil"
)

type Params struct {
	Image        Image
	ReplicaCount int32

	Resources Resources

	Environment Environment
	Secrets     []*Secret

	Services   []*Service
	InitConfig InitConfig

	PersistentVolumeClaims []*PersistentVolumeClaim

	IngressConfig IngressConfig
}

type IngressConfig struct {
	External *ExternalIngressConfig
}

type ExternalIngressConfig struct {
	Port int
}

func (e *ExternalIngressConfig) toValues() map[string]interface{} {
	if e == nil {
		return nil
	}

	return map[string]interface{}{
		"port": e.Port,
	}
}

func (e *ExternalIngressConfig) toClientFacingValues() map[string]interface{} {
	if e == nil {
		return nil
	}

	return map[string]interface{}{
		"host": "TODO: Replace this with the domain name where you will host the service",
	}
}

type PersistentVolumeClaim struct {
	Name      string
	SizeBytes int64
	Path      string
}

func (p *PersistentVolumeClaim) toValues() map[string]interface{} {
	return map[string]interface{}{
		"name": p.Name,
		"size": p.SizeBytes,
		"path": p.Path,
	}
}

type InitConfig struct {
	InitCommands []string
}

func (i InitConfig) toValues() map[string]interface{} {
	m := []map[string]interface{}{}
	for i, v := range i.InitCommands {
		m = append(m, map[string]interface{}{
			"name":    fmt.Sprintf("init-command-%d", i),
			"command": strings.Split(v, " "),
		})
	}
	return map[string]interface{}{
		"initCommands": m,
	}
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
	var externalIngress map[string]interface{}
	if p.IngressConfig.External != nil {
		externalIngress = p.IngressConfig.External.toClientFacingValues()
	}

	return &values.File{
		Values: compactMap(map[string]interface{}{
			"secrets":         sliceToClientFacingValues(p.Secrets),
			"externalIngress": externalIngress,
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
	Credential *ImageCredential
}

func (i Image) toValues() map[string]interface{} {
    values := map[string]interface{}{
        "repository": i.Name,
        "tag":        i.Tag,
    }
    
    if i.Credential != nil {
        values["credential"] = map[string]interface{}{
            "username": i.Credential.Username,
            "password": i.Credential.Password,
        }
    }
    
    return values
}

type ImageCredential struct {
	Username string
	Password string
}

func (p *Params) toYaml() (string, error) {
	values, err := p.toValues()
	if err != nil {
		return "", fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	return chartutil.Values(values.Values).YAML()
}

func (p *Params) toValues() (*values.File, error) {
    vals := map[string]any{
        "replicaCount":           p.ReplicaCount,
        "image":                  p.Image.toValues(),
        "environment":            p.Environment.toValues(),
        "secrets":                sliceToValues(p.Secrets),
        "resources":              p.Resources.toValues(),
        "initConfig":             p.InitConfig.toValues(),
        "persistentVolumeClaims": sliceToValues(p.PersistentVolumeClaims),
        "externalIngress":        p.IngressConfig.External.toValues(),
        "ingress": map[string]any{
            "enabled": false,
        },
        "services": sliceToValues(p.Services),
        "serviceAccount": map[string]any{
            "create": false,
        },
    }

    if p.Image.Credential != nil {
        vals["imagePullSecrets"] = []map[string]interface{}{
            {
                "name": "registry-credentials",
            },
        }
    }

    return &values.File{
        Values: compactMap(vals),
    }, nil
}

func NewServiceChartFromParams(name, version string, params *Params) (*ServiceChart, error) {
	c, err := NewServiceChart(name, version, params)
	if err != nil {
		return nil, fmt.Errorf("error getting service chart: %w", err)
	}

	if err := c.SyncValues(); err != nil {
		return nil, fmt.Errorf("error applying params to service chart: %w", err)
	}

	return c, nil
}

func NewFromProto(name, version string, proto *sidecar_pb.ChartParams) (*ParentChart, error) {
	parentChart, err := NewParentChart(name, version)
	if err != nil {
		return nil, fmt.Errorf("error getting parent chart: %w", err)
	}

	if err := parentChart.SyncValues(); err != nil {
		return nil, fmt.Errorf("error applying params to parent chart: %w", err)
	}

	for _, service := range proto.GetServices() {
		env := Environment{}
		env.LoadFromProto(service.GetEnvironmentConfig())

		secrets := []*Secret{}
		for _, v := range service.GetEnvironmentConfig().GetSecrets() {
			s := &Secret{}
			s.LoadFromProto(v)
			secrets = append(secrets, s)
		}

		services := []*Service{}
		for _, v := range service.GetEndpoints() {
			s := Service{}
			s.Port = int(v.GetPort())
			services = append(services, &s)
		}

		initConfig := InitConfig{}
		for _, v := range service.GetInitConfig().GetInitCommands() {
			initConfig.InitCommands = append(initConfig.InitCommands, v)
		}

		persistentVolumeClaims := []*PersistentVolumeClaim{}
		for _, v := range service.GetPersistentVolumeClaims() {
			p := &PersistentVolumeClaim{
				Name:      v.GetName(),
				SizeBytes: v.GetSizeBytes(),
				Path:      v.GetPath(),
			}
			persistentVolumeClaims = append(persistentVolumeClaims, p)
		}

		var externalIngressConfig *ExternalIngressConfig
		if service.GetIngressConfig().GetExternal() != nil {
			externalIngressConfig = &ExternalIngressConfig{
				Port: int(service.GetIngressConfig().GetExternal().GetPort()),
			}
		}

		var credential *ImageCredential
		if service.GetImage().GetCredential() != nil {
			credential = &ImageCredential{
				Username: service.GetImage().GetCredential().GetUsername(),
				Password: service.GetImage().GetCredential().GetPassword(),
			}
		}

		c, err := NewServiceChartFromParams(service.GetName(), version, &Params{
			ReplicaCount: service.GetReplicaCount(),
			Image: Image{
				Name: service.GetImage().GetName(),
				Tag:  service.GetImage().GetTag(),
				Credential: credential,
			},
			Resources: Resources{
				CPUCoresRequested:    int(service.GetResources().GetCpuCoresRequested()),
				CPUCoresLimit:        int(service.GetResources().GetCpuCoresLimit()),
				MemoryBytesRequested: service.GetResources().GetMemoryBytesRequested(),
				MemoryBytesLimit:     service.GetResources().GetMemoryBytesLimit(),
			},
			IngressConfig: IngressConfig{
				External: externalIngressConfig,
			},
			Environment:            env,
			Secrets:                secrets,
			Services:               services,
			InitConfig:             initConfig,
			PersistentVolumeClaims: persistentVolumeClaims,
		})
		if err != nil {
			return nil, fmt.Errorf("error applying params to service chart: %w", err)
		}

		if err := parentChart.AddService(c); err != nil {
			return nil, fmt.Errorf("error adding service to parent chart: %w", err)
		}
	}

	for _, dep := range proto.GetDependencies() {
		parentChart.AddExternalDependencyFromProto(dep)
	}

	return parentChart, nil
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
