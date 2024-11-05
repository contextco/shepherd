package chart

import (
	"encoding/json"
	"fmt"
)

type Params struct {
	ChartName    string
	ChartVersion string

	Container    Container
	ReplicaCount int
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
