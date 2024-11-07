package clock

import "time"

var Canonical Clock = &realClock{}

type Clock interface {
	Now() time.Time
}

type realClock struct{}

func (c *realClock) Now() time.Time {
	return time.Now()
}
