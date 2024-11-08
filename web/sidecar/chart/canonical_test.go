package chart

import (
	"testing"
)

func TestCanonical(t *testing.T) {
	_, err := Empty()
	if err != nil {
		t.Fatalf("error getting canonical chart: %v", err)
	}
}

func TestTemplateFiles(t *testing.T) {
	files, err := templateFiles()
	if err != nil {
		t.Fatalf("error getting template files: %v", err)
	}

	if len(files) == 0 {
		t.Fatalf("no template files found")
	}

	for _, file := range files {
		if file.Name == "" {
			t.Fatalf("template file name is empty")
		}
	}
}
