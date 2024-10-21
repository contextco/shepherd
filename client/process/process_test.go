package process

import (
	"context"
	"os"
	"testing"
)

func TestRunFromArgs(t *testing.T) {
	// Save original os.Args and restore after test
	originalArgs := os.Args
	defer func() { os.Args = originalArgs }()

	tests := []struct {
		name    string
		args    []string
		wantErr bool
	}{
		{
			name:    "Valid command",
			args:    []string{"echo", "hello"},
			wantErr: false,
		},
		{
			name:    "Invalid command",
			args:    []string{"nonexistentcommand"},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			os.Args = append([]string{"test"}, tt.args...)
			ctx := context.Background()
			_, err := RunFromArgs(ctx)
			if (err != nil) != tt.wantErr {
				t.Errorf("RunFromArgs() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestRun(t *testing.T) {
	tests := []struct {
		name    string
		cmd     string
		args    []string
		wantErr bool
	}{
		{
			name:    "Valid command",
			cmd:     "echo",
			args:    []string{"hello"},
			wantErr: false,
		},
		{
			name:    "Invalid command",
			cmd:     "nonexistentcommand",
			args:    []string{},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx := context.Background()
			p, err := run(ctx, tt.cmd, tt.args...)
			if (err != nil) != tt.wantErr {
				t.Errorf("run() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && p == nil {
				t.Errorf("run() returned nil Process for valid command")
			}
		})
	}
}
