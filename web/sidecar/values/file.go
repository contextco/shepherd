package values

import (
	"fmt"
	"strings"

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

func (v *File) ApplyOverride(o *Override) error {
	bits := strings.Split(o.Path, ".")

	var current map[string]interface{} = v.Values
	if len(bits) == 1 {
		if _, ok := current[bits[0]]; ok {
			return fmt.Errorf("path %s already exists as %v", o.Path, current[bits[0]])
		}
		current[bits[0]] = o.Value
		return nil
	}

	for _, bit := range bits[:len(bits)-1] {
		v, ok := current[bit]
		if !ok {
			newMap := map[string]interface{}{}
			current[bit] = newMap
			current = newMap
		} else {
			if _, ok := v.(map[string]interface{}); !ok {
				return fmt.Errorf("path %s is not a map, it is %T (value: %v)", o.Path, v, v)
			}

			current = v.(map[string]interface{})
		}
	}

	if _, ok := current[bits[len(bits)-1]]; !ok {
		current[bits[len(bits)-1]] = o.Value
	} else {
		return fmt.Errorf("path %s already exists as %v", o.Path, current[bits[len(bits)-1]])
	}

	return nil
}

type Override struct {
	Path  string
	Value interface{}
}
