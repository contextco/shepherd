package clock

import (
	"testing"
	"time"
)

func SetFakeClockForTest(t *testing.T, now time.Time) {
	Canonical = &fakeClock{now: now}
	t.Cleanup(func() {
		Canonical = &realClock{}
	})
}

type fakeClock struct {
	now time.Time
}

func (c *fakeClock) Now() time.Time {
	return c.now
}
