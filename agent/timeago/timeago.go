package timeago

import (
	"fmt"
	"time"
)

// InWords returns a human-readable string representing the time elapsed since the given time.
func InWords(t time.Time) string {
	now := time.Now()
	duration := now.Sub(t)

	if duration < time.Minute {
		return "just now"
	} else if duration < time.Hour {
		minutes := int(duration.Minutes())
		return fmt.Sprintf("%d minute%s ago", minutes, pluralize(minutes))
	} else if duration < 24*time.Hour {
		hours := int(duration.Hours())
		return fmt.Sprintf("%d hour%s ago", hours, pluralize(hours))
	} else if duration < 30*24*time.Hour {
		days := int(duration.Hours() / 24)
		return fmt.Sprintf("%d day%s ago", days, pluralize(days))
	} else if duration < 365*24*time.Hour {
		months := int(duration.Hours() / 24 / 30)
		return fmt.Sprintf("%d month%s ago", months, pluralize(months))
	} else {
		years := int(duration.Hours() / 24 / 365)
		return fmt.Sprintf("%d year%s ago", years, pluralize(years))
	}
}

// pluralize returns "s" if the count is not 1, and an empty string otherwise.
func pluralize(count int) string {
	if count != 1 {
		return "s"
	}
	return ""
}
