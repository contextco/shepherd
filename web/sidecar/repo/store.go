package repo

import (
	"context"
	"io"
)

type RepoStore interface {
	Upload(ctx context.Context, object string, r io.Reader) error
	Exists(ctx context.Context, object string) (bool, error)
	ReadAll(ctx context.Context, object string) ([]byte, error)
}
