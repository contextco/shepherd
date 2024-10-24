package process

import (
	"context"
	"errors"
	"flag"
	"os"
	"os/exec"
	"testing"
)

func TestRunFromArgs(t *testing.T) {
	// Save original os.Args and restore after test
	flagSet = flag.NewFlagSet(os.Args[0], flag.ExitOnError)

	tests := []struct {
		name    string
		args    []string
		wantErr error
	}{
		{
			name:    "Valid command",
			args:    []string{"echo", "hello"},
			wantErr: nil,
		},
		{
			name:    "Invalid command",
			args:    []string{"nonexistentcommand"},
			wantErr: exec.ErrNotFound,
		},
		{
			name:    "No command",
			args:    []string{},
			wantErr: ErrNoCommand,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			flagSet.Parse(tt.args)
			ctx := context.Background()
			_, err := RunFromArgs(ctx)
			if !errors.Is(err, tt.wantErr) {
				t.Errorf("RunFromArgs(os.Args = %v) error = %v, wantErr %v", os.Args, err, tt.wantErr)
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
