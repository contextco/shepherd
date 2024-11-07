package chart

import (
	"fmt"

	"gopkg.in/yaml.v2"
)

type ValuesFile struct {
	Values map[string]interface{}
}

func (v *ValuesFile) Bytes() ([]byte, error) {
	yaml, err := yaml.Marshal(v.Values)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal values: %w", err)
	}
	return yaml, nil
}
