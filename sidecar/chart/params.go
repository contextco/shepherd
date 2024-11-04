package chart

import (
	"fmt"
)

type Params struct {
	Container Container
}

type Container struct {
	Image string
	Tag   string
}

func (p *Params) Validate() error {
	if p.Container.Image == "" {
		return fmt.Errorf("container image is required")
	}

	return nil
}

func NewFromParams(params *Params) (*Chart, error) {
	if err := params.Validate(); err != nil {
		return nil, fmt.Errorf("invalid params: %w", err)
	}

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
