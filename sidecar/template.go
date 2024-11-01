package main

import (
	"embed"
	"fmt"
	"io/fs"
	"path/filepath"

	"helm.sh/helm/v3/pkg/chart/loader"
)

//go:embed all:templates
var template embed.FS

func TemplateFiles() ([]*loader.BufferedFile, error) {
	bufferedFiles := []*loader.BufferedFile{}
	err := fs.WalkDir(template, "templates", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}

		content, err := template.ReadFile(path)
		if err != nil {
			return fmt.Errorf("error reading template file %s: %w", path, err)
		}

		name, err := filepath.Rel("templates", path)
		if err != nil {
			return fmt.Errorf("error getting relative path for %s: %w", path, err)
		}

		bufferedFiles = append(bufferedFiles, &loader.BufferedFile{Name: name, Data: content})
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("error walking templates directory: %w", err)
	}

	return bufferedFiles, nil
}
