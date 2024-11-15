package store

import (
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
)

type MemoryStore struct {
	Files map[string][]byte
}

func NewMemoryStore() *MemoryStore {
	return &MemoryStore{
		Files: make(map[string][]byte),
	}
}

func (m *MemoryStore) Upload(ctx context.Context, object string, r io.Reader) error {
	data, err := io.ReadAll(r)
	if err != nil {
		return err
	}

	m.Files[object] = data
	return nil
}

func (m *MemoryStore) Exists(ctx context.Context, object string) (bool, error) {
	_, exists := m.Files[object]
	return exists, nil
}

func (m *MemoryStore) ReadAll(ctx context.Context, object string) ([]byte, error) {
	data, exists := m.Files[object]
	if !exists {
		return nil, errors.New("object not found")
	}

	return data, nil
}

func (m *MemoryStore) Dump(dir string) error {
	for filename, data := range m.Files {
		filePath := filepath.Join(dir, filename)
		if err := os.MkdirAll(filepath.Dir(filePath), os.ModePerm); err != nil {
			return err
		}

		if err := os.WriteFile(filePath, data, os.ModePerm); err != nil {
			return err
		}
	}
	return nil
}

func (m *MemoryStore) Clear() {
	m.Files = make(map[string][]byte)
}
