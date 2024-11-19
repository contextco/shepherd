package chart

import (
	"fmt"

	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chartutil"
)

type Template struct {
	chart *chart.Chart
}

func (t *Template) Validate() error {
	return t.chart.Validate()
}

func (t *Template) ApplyParams(params *Params) error {
	t.chart.Metadata.Name = params.ChartName
	t.chart.Metadata.Version = params.ChartVersion

	for _, file := range t.chart.Raw {
		if file.Name == chartutil.ValuesfileName {
			values, err := params.toYaml()
			if err != nil {
				return fmt.Errorf("failed to convert params to helm values: %w", err)
			}

			file.Data = []byte(values)
		}
	}

	return nil
}
