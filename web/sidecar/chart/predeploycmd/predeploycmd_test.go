package predeploycmd

import (
	"testing"
)


func TestPreDeployCmd_Generate(t *testing.T) {
	tests := []struct {
		name    string
		command string
		want    []string
	}{
		{
			name:    "test",
			command: "echo test",
			want:    []string{"/bin/sh", "-c", "echo test"},
		},
		{
			name:    "test with quotes",
			command: "echo \"hello world\"",
			want:   []string{"/bin/sh", "-c", "echo \"hello world\""},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := &PreDeployCmd{
				command: tt.command,
			}
			if got := p.Generate(); !equal(got, tt.want) {
				t.Errorf("PreDeployCmd.Generate() = %v, want %v", got, tt.want)
			}
		})
	}
}

func equal(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
