package repo

import (
	"fmt"
	"os"
	"path/filepath"
	"sidecar/chart"
	"sidecar/clock"

	helmrepo "helm.sh/helm/v3/pkg/repo"
)

type indexFile struct {
	*helmrepo.IndexFile
}

func newIndexFile(chart *chart.Chart, archive *ChartArchive) *indexFile {
	idxFile := helmrepo.NewIndexFile()
	idxFile.Generated = clock.Canonical.Now()
	idxFile.MustAdd(chart.Metadata(), filepath.Base(archive.objectName), "", archive.hash)
	idxFile.Entries[chart.Metadata().Name][len(idxFile.Entries[chart.Metadata().Name])-1].Created = clock.Canonical.Now()
	idxFile.SortEntries()
	return &indexFile{IndexFile: idxFile}
}

func (i *indexFile) Bytes() ([]byte, error) {
	tempFile, err := os.CreateTemp("", "sidecar-repo-index")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())

	if err := i.WriteFile(tempFile.Name(), 0644); err != nil {
		return nil, fmt.Errorf("failed to write index file: %w", err)
	}

	buf, err := os.ReadFile(tempFile.Name())
	if err != nil {
		return nil, fmt.Errorf("failed to read temp file: %w", err)
	}

	return buf, nil
}

func newIndexFileFromBytes(buf []byte) (*indexFile, error) {
	tempFile, err := os.CreateTemp("", "sidecar-repo-index")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())

	if err := os.WriteFile(tempFile.Name(), buf, 0644); err != nil {
		return nil, fmt.Errorf("failed to write temp file: %w", err)
	}

	idxFile, err := helmrepo.LoadIndexFile(tempFile.Name())
	if err != nil {
		return nil, fmt.Errorf("failed to load index file: %w", err)
	}
	return &indexFile{IndexFile: idxFile}, nil
}
