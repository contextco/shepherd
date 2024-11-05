package repo

import (
	"context"
	"io"
	"os"
)

type Store interface {
	Upload(ctx context.Context, object string, r io.Reader) error
	Exists(ctx context.Context, object string) (bool, error)
	ReadToTempFile(ctx context.Context, object string) (*os.File, error)
}
