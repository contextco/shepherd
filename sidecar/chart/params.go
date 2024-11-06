package chart

import (
	"encoding/json"
	"fmt"
	"sidecar/generated/sidecar_pb"
)

type Params struct {
	ChartName    string
	ChartVersion string

	Container    Container
	ReplicaCount int
}

func (p *Params) Merge(other *Params) *Params {
	return &Params{
		ChartName:    firstNonEmpty(other.ChartName, p.ChartName),
		ChartVersion: firstNonEmpty(other.ChartVersion, p.ChartVersion),
		Container:    firstNonEmpty(other.Container, p.Container),
		ReplicaCount: firstNonEmpty(other.ReplicaCount, p.ReplicaCount),
	}
}

type Container struct {
	Image string
	Tag   string
}

type helmValues struct {
	ReplicaCount int `json:"replicaCount"`
}

func (p *Params) toValues() (map[string]interface{}, error) {
	hv := helmValues{
		ReplicaCount: p.ReplicaCount,
	}

	bytes, err := json.Marshal(hv)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal helm values: %w", err)
	}

	var values map[string]interface{}
	if err := json.Unmarshal(bytes, &values); err != nil {
		return nil, fmt.Errorf("failed to unmarshal helm values: %w", err)
	}

	return values, nil
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
	return NewFromParams(&Params{
		ChartName:    proto.Name,
		ChartVersion: proto.Version,
		Container: Container{
			Image: proto.GetContainer().GetName(),
			Tag:   proto.GetContainer().GetTag(),
		},
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
