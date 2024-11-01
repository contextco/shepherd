package main

import (
	"embed"
	"fmt"
	"path/filepath"

	"helm.sh/helm/v3/pkg/chart/loader"
)

//go:embed templates
var template embed.FS

func TemplateFiles() ([]*loader.BufferedFile, error) {
	files, err := template.ReadDir("templates")
	if err != nil {
		return nil, fmt.Errorf("error reading templates directory: %w", err)
	}

	bufferedFiles := []*loader.BufferedFile{}
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		content, err := template.ReadFile(filepath.Join("templates", file.Name()))
		if err != nil {
			return nil, fmt.Errorf("error reading template file %s: %w", file.Name(), err)
		}

		bufferedFiles = append(bufferedFiles, &loader.BufferedFile{Name: file.Name(), Data: content})
	}

	return bufferedFiles, nil
}
