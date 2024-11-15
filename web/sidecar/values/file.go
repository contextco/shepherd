package values

import (
	"fmt"

	"gopkg.in/yaml.v2"
)

type File struct {
	Values map[string]interface{}
}

func Empty() *File {
	return &File{Values: map[string]interface{}{}}
}

func (v *File) Bytes() ([]byte, error) {
	yaml, err := yaml.Marshal(v.Values)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal values: %w", err)
	}
	return yaml, nil
}
