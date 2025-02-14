package testenv

import (
	"os"
	"regexp"
	"testing"

	"github.com/joho/godotenv"
)

const projectDirName = "sidecar"

func Load(t *testing.T) error {
	t.Helper()

	re := regexp.MustCompile(`^(.*` + projectDirName + `)`)
	cwd, _ := os.Getwd()
	rootPath := re.Find([]byte(cwd))

	err := godotenv.Load(string(rootPath) + `/.env`)
	if err != nil {
		return err
	}

	return nil
}

func MustLoad(t *testing.T) {
	t.Helper()

	err := Load(t)
	if err != nil {
		t.Fatalf("failed to load .env file: %v", err)
	}
}
