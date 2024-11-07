package server

import (
	"context"
	"testing"

	sidecar_pb "sidecar/generated/sidecar_pb"
)

func TestValidateChart(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		chart   *sidecar_pb.ChartParams
		wantErr bool
	}{
		{
			name: "valid chart",
			chart: &sidecar_pb.ChartParams{
				Name:    "test",
				Version: "0.1.0",
			},
			wantErr: false,
		},
		{
			name:    "empty chart",
			chart:   &sidecar_pb.ChartParams{},
			wantErr: false,
		},
		{
			name:    "nil chart",
			chart:   nil,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			s := &Server{}
			req := &sidecar_pb.ValidateChartRequest{
				Chart: tt.chart,
			}
			_, err := s.ValidateChart(context.Background(), req)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateChart() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}

}
