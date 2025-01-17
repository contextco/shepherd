package retry

import (
	"context"
	"fmt"
	"math"
	"time"
)

type Function func() error

func RetryExponential(ctx context.Context, fn Function, initialBackoff time.Duration, maxBackoff time.Duration) error {
	if err := fn(); err == nil {
		return nil
	}

	backoff := initialBackoff

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(backoff):
			err := fn()
			if err == nil {
				return nil
			}

			backoff = nextBackoff(backoff, maxBackoff)
			if backoff > maxBackoff {
				return fmt.Errorf("max backoff reached: %s; last error: %w", backoff, err)
			}
		}
	}
}

func nextBackoff(backoff time.Duration, maxBackoff time.Duration) time.Duration {
	return time.Duration(math.Min(
		float64(backoff*2),
		float64(maxBackoff),
	))
}
