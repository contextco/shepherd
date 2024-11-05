package chart

import "testing"

func TestMerge(t *testing.T) {
	tests := []struct {
		name     string
		base     *Params
		override *Params
		want     *Params
	}{
		{
			name: "empty override",
			base: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Container: Container{
					Image: "base-image",
					Tag:   "base-tag",
				},
				ReplicaCount: 1,
			},
			override: &Params{},
			want: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Container: Container{
					Image: "base-image",
					Tag:   "base-tag",
				},
				ReplicaCount: 1,
			},
		},
		{
			name: "full override",
			base: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Container: Container{
					Image: "base-image",
					Tag:   "base-tag",
				},
				ReplicaCount: 1,
			},
			override: &Params{
				ChartName:    "override-chart",
				ChartVersion: "2.0.0",
				Container: Container{
					Image: "override-image",
					Tag:   "override-tag",
				},
				ReplicaCount: 2,
			},
			want: &Params{
				ChartName:    "override-chart",
				ChartVersion: "2.0.0",
				Container: Container{
					Image: "override-image",
					Tag:   "override-tag",
				},
				ReplicaCount: 2,
			},
		},
		{
			name: "partial override",
			base: &Params{
				ChartName:    "base-chart",
				ChartVersion: "1.0.0",
				Container: Container{
					Image: "base-image",
					Tag:   "base-tag",
				},
				ReplicaCount: 1,
			},
			override: &Params{
				ChartVersion: "2.0.0",
				ReplicaCount: 2,
			},
			want: &Params{
				ChartName:    "base-chart",
				ChartVersion: "2.0.0",
				Container: Container{
					Image: "base-image",
					Tag:   "base-tag",
				},
				ReplicaCount: 2,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.base.Merge(tt.override)
			if got.ChartName != tt.want.ChartName {
				t.Errorf("ChartName = %v, want %v", got.ChartName, tt.want.ChartName)
			}
			if got.ChartVersion != tt.want.ChartVersion {
				t.Errorf("ChartVersion = %v, want %v", got.ChartVersion, tt.want.ChartVersion)
			}
			if got.Container != tt.want.Container {
				t.Errorf("Container = %v, want %v", got.Container, tt.want.Container)
			}
			if got.ReplicaCount != tt.want.ReplicaCount {
				t.Errorf("ReplicaCount = %v, want %v", got.ReplicaCount, tt.want.ReplicaCount)
			}
		})
	}
}
