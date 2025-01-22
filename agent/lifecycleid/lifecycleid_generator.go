package lifecycleid

import (
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

type LifecycleIDGenerator struct {
	LifecycleIDFilePath string
}

func NewLifecycleIDGenerator(lifecycleIDFilePath string) *LifecycleIDGenerator {
	return &LifecycleIDGenerator{
		LifecycleIDFilePath: lifecycleIDFilePath,
	}
}

func (l *LifecycleIDGenerator) Generate() string {
	const (
		DirectoryPermissions = 0755 // Owner can read/write/execute, others can read/execute
		FilePermissions      = 0644 // Owner can read/write, others can read only
	)

	filePath := l.LifecycleIDFilePath
    
    // Try to read existing ID
    content, err := os.ReadFile(filePath)
    if err == nil && len(content) > 0 {
		log.Printf("Found existing lifecycle ID: %s", string(content))
        return strings.TrimSpace(string(content))
    }
    
    newID := uuid.New().String()
    
    // Ensure directory exists
    if err := os.MkdirAll(filepath.Dir(filePath), DirectoryPermissions); err != nil {
        log.Printf("Failed to create directory: %v", err)
        return newID
    }
    
    // Write new ID to file
    if err := os.WriteFile(filePath, []byte(newID), FilePermissions); err != nil {
        log.Printf("Failed to write lifecycle ID: %v", err)
    }
    
    return newID
}
