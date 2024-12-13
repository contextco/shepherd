# Build stage
FROM golang:1.23.2-alpine3.20 AS builder

WORKDIR /app

# Install git
RUN apk add --no-cache git

# Copy the gateway directory
COPY . gateway/

# Set working directory to gateway
WORKDIR /app/gateway

# Copy go.mod and go.sum (from gateway directory)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o gateway

# Final stage
FROM alpine:3.18

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/gateway/gateway .

# Create non-root user
RUN adduser -D gateway
USER gateway

# Set environment variables
ENV PORT=8081

# Expose the port
EXPOSE 8081

# Run the gateway
CMD ["./gateway"]