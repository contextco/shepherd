.PHONY: test test-coverage test-verbose clean

# Default target
all: test

# Run all tests recursively
test:
	go test ./...

# Run tests with coverage
test-coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Run tests with verbose output
test-verbose:
	go test -v ./...

# Clean test cache and coverage files
clean:
	go clean -testcache
	rm -f coverage.out coverage.html

# Run tests for a specific package
test-package:
	@read -p "Enter package path: " pkg; \
	go test -v ./$${pkg}/...

# Run tests and show race conditions
test-race:
	go test -race ./... 