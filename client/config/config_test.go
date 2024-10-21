package config

import (
	"os"
	"testing"
)

func TestDefine(t *testing.T) {
	tests := []struct {
		name         string
		defaultValue interface{}
		expected     interface{}
	}{
		{"string-var", "default", "default"},
		{"int-var", 42, 42},
		{"bool-var", true, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cv := Define(tt.name, tt.defaultValue, "test usage")
			value, err := cv.Value()
			if err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if value != tt.expected {
				t.Errorf("Expected %v, got %v", tt.expected, value)
			}
		})
	}
}

func TestConfigVarValue(t *testing.T) {
	tests := []struct {
		name         string
		defaultValue string
		envValue     string
		flagValue    string
		expected     string
	}{
		{
			name:         "default",
			defaultValue: "default",
			envValue:     "",
			flagValue:    "",
			expected:     "default",
		},
		{
			name:         "env-override",
			defaultValue: "default",
			envValue:     "env-value",
			flagValue:    "",
			expected:     "env-value",
		},
		{
			name:         "flag-override",
			defaultValue: "default",
			envValue:     "env-value",
			flagValue:    "flag-value",
			expected:     "flag-value",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cv := Define(tt.name, tt.defaultValue, "test usage")

			if tt.envValue != "" {
				os.Setenv(nameToEnv(tt.name), tt.envValue)
				defer os.Unsetenv(nameToEnv(tt.name))
			}

			if tt.flagValue != "" {
				flagSet.Set(tt.name, tt.flagValue)
			}

			value, err := cv.Value()
			if err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if value != tt.expected {
				t.Errorf("Expected %v, got %v", tt.expected, value)
			}
		})
	}
}

func TestNameToEnv(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"test-var", "TEST_VAR"},
		{"testVar", "TESTVAR"},
		{"test_var", "TEST_VAR"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := nameToEnv(tt.input)
			if result != tt.expected {
				t.Errorf("Expected %s, got %s", tt.expected, result)
			}
		})
	}
}

func TestParseType(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected interface{}
		wantErr  bool
	}{
		{"string", "test", "test", false},
		{"int", "42", 42, false},
		{"bool-true", "true", true, false},
		{"bool-false", "false", false, false},
		{"invalid-int", "not-an-int", 0, true},
		{"invalid-bool", "not-a-bool", false, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			switch tt.expected.(type) {
			case string:
				result, err := parseType[string](tt.input)
				if (err != nil) != tt.wantErr {
					t.Errorf("parseType() error = %v, wantErr %v", err, tt.wantErr)
					return
				}
				if result != tt.expected {
					t.Errorf("Expected %v, got %v", tt.expected, result)
				}
			case int:
				result, err := parseType[int](tt.input)
				if (err != nil) != tt.wantErr {
					t.Errorf("parseType() error = %v, wantErr %v", err, tt.wantErr)
					return
				}
				if result != tt.expected {
					t.Errorf("Expected %v, got %v", tt.expected, result)
				}
			case bool:
				result, err := parseType[bool](tt.input)
				if (err != nil) != tt.wantErr {
					t.Errorf("parseType() error = %v, wantErr %v", err, tt.wantErr)
					return
				}
				if result != tt.expected {
					t.Errorf("Expected %v, got %v", tt.expected, result)
				}
			}
		})
	}
}
