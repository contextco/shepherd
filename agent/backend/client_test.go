package backend

import (
	"testing"
)

func TestNewClient(t *testing.T) {
	tests := []struct {
		name        string
		addr        string
		bearerToken string
		wantErr     bool
	}{
		{
			name:        "valid client creation",
			addr:        "http://localhost:8080",
			bearerToken: "test-token",
			wantErr:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewClient(tt.addr, tt.bearerToken, Identity{
				LifecycleID: "test-lifecycle-id",
				Name:        "test-name",
			})
			if !tt.wantErr && err != nil {
				t.Errorf("NewClient() returned error: %v", err)
			}
			if tt.wantErr && err == nil {
				t.Errorf("NewClient() did not return error when it should have")
			}
		})
	}
}
