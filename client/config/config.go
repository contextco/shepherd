package config

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
)

var (
	flagSet = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
)

func Init(args []string) {
	flagSet.Parse(args)
}

type ConfigVar[T comparable] struct {
	name         string
	defaultValue T
	required     bool
}

func Define[T comparable](name string, defaultValue T, usage string) *ConfigVar[T] {
	_ = flagSet.String(name, "", usage)
	return &ConfigVar[T]{
		name:         name,
		defaultValue: defaultValue,
	}
}

func MustDefine[T comparable](name string, usage string) *ConfigVar[T] {
	c := Define(name, *new(T), usage)
	c.required = true
	return c
}

func (c *ConfigVar[T]) Value() (T, error) {
	v := flagSet.Lookup(c.name)

	var zero T
	if v == nil {
		return zero, fmt.Errorf("required flag %s not configured in this flag set", c.name)
	}

	parsed, err := parseType[T](v.Value.String())
	if err != nil {
		return zero, err
	}

	if parsed != zero {
		return parsed, nil
	}

	envValue := os.Getenv(nameToEnv(c.name))
	parsed, err = parseType[T](envValue)
	if err != nil {
		return zero, err
	}

	if parsed != zero {
		return parsed, nil
	}

	if c.required && parsed == zero {
		return zero, fmt.Errorf("required config variable %s not set", c.name)
	}

	return c.defaultValue, nil
}

func (c *ConfigVar[T]) MustValue() T {
	v, err := c.Value()
	if err != nil {
		log.Fatalf("Failed to get value for %s: %s", c.name, err)
	}
	return v
}

func nameToEnv(name string) string {
	return strings.ToUpper(strings.ReplaceAll(name, "-", "_"))
}

func parseType[T comparable](v string) (T, error) {
	var zero T
	n, err := fmt.Sscanf(v, "%v", &zero)
	if err != nil && err != io.EOF && n == 0 {
		return zero, err
	}

	return zero, nil
}

func Production() bool {
	env := os.Getenv("ENV")

	return env == "production"
}

func Development() bool {
	return !Production()
}
