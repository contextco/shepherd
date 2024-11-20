package values

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestApplyOverride(t *testing.T) {
	tests := []struct {
		name     string
		initial  map[string]interface{}
		override *Override
		want     map[string]interface{}
		wantErr  bool
	}{
		{
			name:    "simple value",
			initial: map[string]interface{}{},
			override: &Override{
				Path:  "foo",
				Value: "bar",
			},
			want: map[string]interface{}{
				"foo": "bar",
			},
		},
		{
			name:    "nested path",
			initial: map[string]interface{}{},
			override: &Override{
				Path:  "foo.bar.baz",
				Value: "qux",
			},
			want: map[string]interface{}{
				"foo": map[string]interface{}{
					"bar": map[string]interface{}{
						"baz": "qux",
					},
				},
			},
		},
		{
			name: "nested path with separate existing value",
			initial: map[string]interface{}{
				"foo": map[string]interface{}{
					"gam": "baz",
				},
			},
			override: &Override{
				Path:  "foo.bar.baz",
				Value: "qux",
			},
			want: map[string]interface{}{
				"foo": map[string]interface{}{
					"gam": "baz",
					"bar": map[string]interface{}{
						"baz": "qux",
					},
				},
			},
		},
		{
			name: "existing path error",
			initial: map[string]interface{}{
				"foo": "bar",
			},
			override: &Override{
				Path:  "foo",
				Value: "baz",
			},
			wantErr: true,
		},
		{
			name: "path through non-map error",
			initial: map[string]interface{}{
				"foo": "bar",
			},
			override: &Override{
				Path:  "foo.bar",
				Value: "baz",
			},
			wantErr: true,
		},
		{
			name: "path already exists error",
			initial: map[string]interface{}{
				"foo": "bar",
			},
			override: &Override{
				Path:  "foo.bar",
				Value: "baz",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			f := &File{Values: tt.initial}
			err := f.ApplyOverride(tt.override)

			if tt.wantErr {
				if err == nil {
					t.Error("expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}

			if diff := cmp.Diff(tt.want, f.Values); diff != "" {
				t.Errorf("values mismatch (-want +got):\n%s", diff)
			}
		})
	}
}
