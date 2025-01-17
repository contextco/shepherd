package timeago

import (
	"testing"
	"time"
)

func TestFormatTimeAgo(t *testing.T) {
	now := time.Now()

	testCases := []struct {
		name     string
		input    time.Time
		expected string
	}{
		{"Just now", now.Add(-30 * time.Second), "just now"},
		{"One minute ago", now.Add(-1 * time.Minute), "1 minute ago"},
		{"Multiple minutes ago", now.Add(-5 * time.Minute), "5 minutes ago"},
		{"One hour ago", now.Add(-1 * time.Hour), "1 hour ago"},
		{"Multiple hours ago", now.Add(-3 * time.Hour), "3 hours ago"},
		{"One day ago", now.Add(-24 * time.Hour), "1 day ago"},
		{"Multiple days ago", now.Add(-3 * 24 * time.Hour), "3 days ago"},
		{"One month ago", now.Add(-30 * 24 * time.Hour), "1 month ago"},
		{"Multiple months ago", now.Add(-3 * 30 * 24 * time.Hour), "3 months ago"},
		{"One year ago", now.Add(-365 * 24 * time.Hour), "1 year ago"},
		{"Multiple years ago", now.Add(-3 * 365 * 24 * time.Hour), "3 years ago"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := InWords(tc.input)
			if result != tc.expected {
				t.Errorf("InWords(%v) = %v; want %v", tc.input, result, tc.expected)
			}
		})
	}
}

func TestPluralize(t *testing.T) {
	testCases := []struct {
		name     string
		input    int
		expected string
	}{
		{"Singular", 1, ""},
		{"Plural", 2, "s"},
		{"Zero", 0, "s"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := pluralize(tc.input)
			if result != tc.expected {
				t.Errorf("pluralize(%d) = %q; want %q", tc.input, result, tc.expected)
			}
		})
	}
}
