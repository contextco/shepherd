package config

import (
	"os"
	"testing"
)

func TestDefineString(t *testing.T) {
	cv := Define("string-var", "default", "test usage")
	value, err := cv.Value()
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if value != "default" {
		t.Errorf("Expected %v, got %v", "default", value)
	}
}

func TestDefineInt(t *testing.T) {
	cv := Define("int-var", 42, "test usage")
	value, err := cv.Value()
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if value != 42 {
		t.Errorf("Expected %v, got %v", 42, value)
	}
}

func TestDefineBool(t *testing.T) {
	cv := Define("bool-var", true, "test usage")
	value, err := cv.Value()
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if value != true {
		t.Errorf("Expected %v, got %v", true, value)
	}
}

func TestMustDefineString(t *testing.T) {
	cv := MustDefine[string]("required-string", "test usage")
	Init([]string{"-required-string", "flag-value"})
	if !cv.required {
		t.Error("Expected required to be true")
	}

	value, err := cv.Value()
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if value != "flag-value" {
		t.Errorf("Expected flag-value, got %v", value)
	}
}

func TestMustDefineInt(t *testing.T) {
	cv := MustDefine[int]("required-int", "test usage")
	if !cv.required {
		t.Error("Expected required to be true")
	}

	Init([]string{"--required-int", "42"})

	value, err := cv.Value()
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	if value != 42 {
		t.Errorf("Expected 0, got %v", value)
	}
}

func TestMustDefineMissingValue(t *testing.T) {
	cv := MustDefine[string]("missing", "test usage")
	_, err := cv.Value()
	if err == nil {
		t.Error("Expected error for missing required value")
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
