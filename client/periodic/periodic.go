package periodic

import (
	"context"
	"time"

	"golang.org/x/exp/rand"
)

func Run(ctx context.Context, fn func() error, interval time.Duration) error {
	return RunWithJitter(ctx, fn, interval, 0)
}

func RunWithJitter(ctx context.Context, fn func() error, interval time.Duration, jitter time.Duration) error {
	tick := time.After(interval)

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-tick:
			if err := fn(); err != nil {
				return err
			}

			jitter := time.Duration(rand.Intn(int(jitter))) * time.Duration(rand.Intn(2)-1)
			tick = time.After(interval + jitter)
		}
	}
}
