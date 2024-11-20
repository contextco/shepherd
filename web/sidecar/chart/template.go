package chart

import (
	"fmt"
	"sidecar/values"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chartutil"
)

type Template struct {
	chart *chart.Chart
}

func (t *Template) Validate() error {
	return t.chart.Validate()
}

func (t *Template) SetValues(values *values.File) error {
	for _, file := range t.chart.Raw {
		if file.Name == chartutil.ValuesfileName {
			yaml, err := values.Bytes()
			if err != nil {
				return fmt.Errorf("failed to marshal values: %w", err)
			}
			file.Data = yaml
		}
	}
	return nil
}
