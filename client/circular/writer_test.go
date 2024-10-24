package circular

import (
	"testing"
	"time"
)

func TestNewBuffer(t *testing.T) {
	b := NewBuffer(5)
	if b.size != 5 {
		t.Errorf("Expected buffer size to be 5, got %d", b.size)
	}
	if b.head != 0 {
		t.Errorf("Expected head to start at 0, got %d", b.head)
	}
	if b.full {
		t.Error("Expected new buffer to not be full")
	}
}

func TestBufferWrite(t *testing.T) {
	b := NewBuffer(3)

	testCases := []struct {
		input    string
		expected []string
	}{
		{"line1\n", []string{"line1"}},
		{"line2\nline3\n", []string{"line1", "line2", "line3"}},
		{"line4\n", []string{"line2", "line3", "line4"}},
	}

	for _, tc := range testCases {
		b.Write([]byte(tc.input))
		lines := b.Lines(3)

		for i, expected := range tc.expected {
			if lines[i].Text != expected {
				t.Errorf("Expected line %d to be %q, got %q", i, expected, lines[i].Text)
			}
		}
	}
}

func TestPartialWrites(t *testing.T) {
	b := NewBuffer(2)

	b.Write([]byte("partial"))
	b.Write([]byte(" line\n"))
	b.Write([]byte("second line\n"))

	lines := b.Lines(2)
	expected := []string{"partial line", "second line"}

	for i, exp := range expected {
		if lines[i].Text != exp {
			t.Errorf("Expected line %d to be %q, got %q", i, exp, lines[i].Text)
		}
	}
}

func TestNewLine(t *testing.T) {
	text := "test line"
	before := time.Now()
	line := NewLine(text)
	after := time.Now()

	if line.Text != text {
		t.Errorf("Expected text to be %q, got %q", text, line.Text)
	}
	if line.Time.Before(before) || line.Time.After(after) {
		t.Error("Line timestamp is outside expected range")
	}
}

func TestBufferLines(t *testing.T) {
	b := NewBuffer(3)

	// Test empty buffer
	if len(b.Lines(3)) != 0 {
		t.Error("Expected empty buffer to return no lines")
	}

	// Test partially filled buffer
	b.Add("line1")
	b.Add("line2")
	lines := b.Lines(3)
	if len(lines) != 2 {
		t.Errorf("Expected 2 lines, got %d", len(lines))
	}

	// Test full buffer
	b.Add("line3")
	b.Add("line4")
	lines = b.Lines(3)
	if len(lines) != 3 {
		t.Errorf("Expected 3 lines, got %d", len(lines))
	}
	expected := []string{"line2", "line3", "line4"}
	for i, exp := range expected {
		if lines[i].Text != exp {
			t.Errorf("Expected line %d to be %q, got %q", i, exp, lines[i].Text)
		}
	}
}
