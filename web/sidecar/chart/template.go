package chart

import "helm.sh/helm/v3/pkg/chart"

type Template struct {
	chart *chart.Chart
}

func (t *Template) Validate() error {
	return t.chart.Validate()
}

func (t *Template) ApplyParams(params *Params) (*Chart, error) {
	t.chart.Metadata.Name = params.ChartName
	t.chart.Metadata.Version = params.ChartVersion

	return &Chart{template: t, params: params}, nil
}
