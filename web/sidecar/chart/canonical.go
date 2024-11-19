package chart

import (
	"embed"
	"fmt"
	"io/fs"
	"path/filepath"

	"helm.sh/helm/v3/pkg/chart/loader"
)

//go:embed all:templates
var template embed.FS

func NewServiceChart() (*ServiceChart, error) {
	template, err := loadTemplate("templates/service")
	if err != nil {
		return nil, fmt.Errorf("error getting canonical template: %w", err)
	}

	return &ServiceChart{Chart: &Chart{template: template, params: &Params{}}}, nil
}

func NewParentChart() (*ParentChart, error) {
	template, err := loadTemplate("templates/parent")
	if err != nil {
		return nil, fmt.Errorf("error getting canonical template: %w", err)
	}

	return &ParentChart{Chart: &Chart{template: template, params: &Params{}}}, nil
}

func loadTemplate(dir string) (*Template, error) {
	files, err := templateFiles(dir)
	if err != nil {
		return nil, fmt.Errorf("error getting template files: %w", err)
	}

	chart, err := loader.LoadFiles(files)
	if err != nil {
		return nil, fmt.Errorf("error loading template files: %w", err)
	}

	return &Template{chart: chart}, nil
}

func templateFiles(dir string) ([]*loader.BufferedFile, error) {
	bufferedFiles := []*loader.BufferedFile{}
	err := fs.WalkDir(template, dir, func(path string, d fs.DirEntry, err error) error {
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

		name, err := filepath.Rel(dir, path)
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
