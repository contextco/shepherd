package chart

import (
	"testing"
)

func TestChartValidate(t *testing.T) {
	tests := []struct {
		name    string
		params  *Params
		wantErr bool
	}{
		{
			name: "valid params",
			params: &Params{
				Image: Image{
					Name: "nginx",
					Tag:  "latest",
				},
				ReplicaCount: 1,
			},
			wantErr: false,
		},
		{
			name: "invalid replica count",
			params: &Params{
				ReplicaCount: -1,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chart, err := NewFromParams(tt.params)
			if err != nil {
				t.Fatalf("failed to create chart: %v", err)
			}

			err = chart.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Chart.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
