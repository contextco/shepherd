package chart

import (
	"fmt"
	"math"
	"strings"

	"agent/cluster"
	"sidecar/chart/predeploycmd"
	"sidecar/generated/sidecar_pb"
	"sidecar/values"

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

	MetaEnvironmentFieldsEnabled bool
}

type IngressConfig struct {
	Enabled    bool
	Port       int
	Preference sidecar_pb.IngressPreference
}

func (i IngressConfig) toValues() map[string]interface{} {
	if !i.Enabled {
		return map[string]interface{}{
			"enabled": false,
		}
	}

	var scheme string
	switch i.Preference {
	case sidecar_pb.IngressPreference_PREFER_EXTERNAL:
		scheme = "external"
	case sidecar_pb.IngressPreference_PREFER_INTERNAL:
		scheme = "internal"
	}

	return map[string]interface{}{
		"enabled": true,
		"scheme":  scheme,
		"port":    i.Port,
	}
}

func (i IngressConfig) toClientFacingValues() map[string]interface{} {
	if !i.Enabled {
		return nil
	}

	var scheme string
	switch i.Preference {
	case sidecar_pb.IngressPreference_PREFER_EXTERNAL:
		scheme = "external"
	case sidecar_pb.IngressPreference_PREFER_INTERNAL:
		scheme = "internal"
	}

	return map[string]interface{}{
		"scheme":  scheme,
		"enabled": true,
		"port":    i.Port,
		"external": map[string]interface{}{
			"host": "TODO: Replace this with the domain name where you will host the service. Note, this field has no effect if the ingress is internal.",
		},
	}
}

type PersistentVolumeClaim struct {
	Name      string
	SizeBytes int64
	Path      string
}

func bytesToGi(bytes int64) int64 {
	gi := float64(bytes) / (1024 * 1024 * 1024)
	roundedGi := math.Ceil(gi)
	return int64(roundedGi)
}

func (p *PersistentVolumeClaim) toValues() map[string]interface{} {
	return map[string]interface{}{
		"name": p.Name,
		"size": bytesToGi(p.SizeBytes),
		"path": p.Path,
	}
}

type InitConfig struct {
	InitCommands []string
}

func (i InitConfig) toValues() map[string]interface{} {
	m := []map[string]interface{}{}
	for i, v := range i.InitCommands {
		predeploycmd, _ := predeploycmd.New(v)
		command := predeploycmd.Generate()

		m = append(m, map[string]interface{}{
			"name":    fmt.Sprintf("init-command-%d", i),
			"command": command,
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
	return &values.File{
		Values: compactMap(map[string]interface{}{
			"secrets": sliceToClientFacingValues(p.Secrets),
			"ingress": p.IngressConfig.toClientFacingValues(),
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
	Name       string
	Tag        string
	Credential *ImageCredential
	PullPolicy sidecar_pb.ImagePullPolicy
}

func (i Image) toValues() map[string]interface{} {
	values := map[string]interface{}{
		"repository": i.Name,
		"tag":        i.Tag,
	}

	switch i.PullPolicy {
	case sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_ALWAYS:
		values["pullPolicy"] = "Always"
	case sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_IF_NOT_PRESENT:
		values["pullPolicy"] = "IfNotPresent"
	case sidecar_pb.ImagePullPolicy_IMAGE_PULL_POLICY_NEVER:
		values["pullPolicy"] = "Never"
	}

	if i.Credential != nil {
		values["registry"] = i.Credential.Registry
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
	Registry string
}

func (p *Params) toYaml() (string, error) {
	values, err := p.toValues()
	if err != nil {
		return "", fmt.Errorf("failed to convert params to helm values: %w", err)
	}

	return chartutil.Values(values.Values).YAML()
}

func (p *Params) MetaEnvironmentFields() map[string]interface{} {
	if !p.MetaEnvironmentFieldsEnabled {
		return map[string]interface{}{
			"enabled": false,
		}
	}

	return map[string]interface{}{
		"enabled": true,
		"fields": []map[string]interface{}{
			{
				"name":      cluster.HELM_RELEASE_NAME_ENV_KEY,
				"fieldPath": "metadata.labels['app.kubernetes.io/instance']",
			},
			{
				"name":      cluster.HELM_NAMESPACE_ENV_KEY,
				"fieldPath": "metadata.namespace",
			},
		},
	}
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
		"ingress":                p.IngressConfig.toValues(),
		"services":               sliceToValues(p.Services),
		"serviceAccount": map[string]any{
			"create": false,
		},
		"metaEnvironmentFields": p.MetaEnvironmentFields(),
	}

	if p.Image.Credential != nil {
		dockerImageRepo := strings.ReplaceAll(p.Image.Name, "/", "-")
		imagePullSecretsName := "registry-credentials-" + dockerImageRepo

		vals["imagePullSecrets"] = []map[string]interface{}{
			{
				"name": imagePullSecretsName,
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

		var ingressConfig IngressConfig
		if service.IngressConfig != nil {
			ingressConfig = IngressConfig{
				Enabled:    true,
				Port:       int(service.GetIngressConfig().GetPort()),
				Preference: service.GetIngressConfig().GetPreference(),
			}
		}

		var credential *ImageCredential
		if service.GetImage().GetCredential() != nil {
			credential = &ImageCredential{
				Username: service.GetImage().GetCredential().GetUsername(),
				Password: service.GetImage().GetCredential().GetPassword(),
				Registry: registryTypeToValues(service.GetImage().GetCredential().GetRegistryType()),
			}
		}

		c, err := NewServiceChartFromParams(service.GetName(), version, &Params{
			ReplicaCount: service.GetReplicaCount(),
			Image: Image{
				Name:       service.GetImage().GetName(),
				Tag:        service.GetImage().GetTag(),
				Credential: credential,
				PullPolicy: service.GetImage().GetPullPolicy(),
			},
			Resources: Resources{
				CPUCoresRequested:    int(service.GetResources().GetCpuCoresRequested()),
				CPUCoresLimit:        int(service.GetResources().GetCpuCoresLimit()),
				MemoryBytesRequested: service.GetResources().GetMemoryBytesRequested(),
				MemoryBytesLimit:     service.GetResources().GetMemoryBytesLimit(),
			},
			IngressConfig:                ingressConfig,
			Environment:                  env,
			Secrets:                      secrets,
			Services:                     services,
			InitConfig:                   initConfig,
			PersistentVolumeClaims:       persistentVolumeClaims,
			MetaEnvironmentFieldsEnabled: service.GetEnvironmentConfig().GetMetaEnvironmentFieldsEnabled(),
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

func registryTypeToValues(registryType sidecar_pb.RegistryType) string {
	switch registryType {
	case sidecar_pb.RegistryType_REGISTRY_TYPE_GITHUB:
		return "github"
	case sidecar_pb.RegistryType_REGISTRY_TYPE_GITLAB:
		return "gitlab"
	case sidecar_pb.RegistryType_REGISTRY_TYPE_DOCKER:
		return "docker"
	default:
		return "docker"
	}
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
