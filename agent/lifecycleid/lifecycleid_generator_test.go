package lifecycleid

import (
    "os"
    "path/filepath"
    "testing"
)

func TestLifecycleIDGenerator_Generate(t *testing.T) {
    // Create temp directory for tests
    tmpDir := t.TempDir()
    filePath := filepath.Join(tmpDir, "lifecycle.id")

    t.Run("generates new ID when file doesn't exist", func(t *testing.T) {
        generator := NewLifecycleIDGenerator(filePath)
        id1 := generator.Generate()
        if id1 == "" {
            t.Error("Generated ID should not be empty")
        }
    })

    t.Run("returns same ID when file exists", func(t *testing.T) {
        generator := NewLifecycleIDGenerator(filePath)
        id1 := generator.Generate()
        id2 := generator.Generate()
        if id1 != id2 {
            t.Errorf("Expected same ID on second call, got %s != %s", id1, id2)
        }
    })

    t.Run("handles invalid file path", func(t *testing.T) {
        invalidPath := filepath.Join(tmpDir, "nonexistent", "lifecycle.id")
        generator := NewLifecycleIDGenerator(invalidPath)
        id := generator.Generate()
        if id == "" {
            t.Error("Should generate ID even with invalid path")
        }
    })

    t.Run("creates directory if not exists", func(t *testing.T) {
        newDir := filepath.Join(tmpDir, "newdir")
        filePath := filepath.Join(newDir, "lifecycle.id")
        generator := NewLifecycleIDGenerator(filePath)
        generator.Generate()
        
        if _, err := os.Stat(newDir); os.IsNotExist(err) {
            t.Error("Directory should have been created")
        }
    })
}
