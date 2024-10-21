package config

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

var flagSet = flag.NewFlagSet(os.Args[0], flag.ExitOnError)

func Init() {
	flagSet.Parse(os.Args[1:])
}

type ConfigVar[T any] struct {
	name         string
	defaultValue T
}

func Define[T any](name string, defaultValue T, usage string) *ConfigVar[T] {
	_ = flagSet.String(name, "", usage)
	return &ConfigVar[T]{
		name:         name,
		defaultValue: defaultValue,
	}
}

func (c *ConfigVar[T]) Value() (T, error) {
	if v := flagSet.Lookup(c.name); v != nil && v.Value.String() != "" {
		return parseType[T](v.Value.String())
	}
	v, ok := os.LookupEnv(nameToEnv(c.name))
	if ok {
		return parseType[T](v)
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

func parseType[T any](v string) (T, error) {
	switch any(v).(type) {
	case string:
		return any(v).(T), nil
	case int:
		i, err := strconv.Atoi(v)
		if err != nil {
			return any(0).(T), err
		}
		return any(i).(T), nil
	case bool:
		b, err := strconv.ParseBool(v)
		if err != nil {
			return any(false).(T), err
		}
		return any(b).(T), nil
	}

	return any(nil).(T), fmt.Errorf("unsupported type %T", v)
}
