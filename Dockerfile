# # Stage 1: The 'builder' stage to compile the Go application
# FROM golang:1.24-alpine AS builder
# # Set the working directory inside the container
# WORKDIR /app

# # Copy the module files and download dependencies
# COPY go.mod go.sum ./
# RUN go mod download

# # Copy the rest of the application source code
# COPY *.go ./



# COPY go_freeze_time_amd64 /lib/keploy/go_freeze_time_amd64

# # Set suitable permissions
# RUN chmod +x /lib/keploy/go_freeze_time_amd64

# # Run the binary to set up the time freezing environment
# RUN /lib/keploy/go_freeze_time_amd64


# # Build the Go application into a static binary
# # CGO_ENABLED=0 is important for creating a static binary that can run in a minimal image
# RUN CGO_ENABLED=0 GOOS=linux go build -tags=faketime -o /main .

# # Stage 2: The 'final' stage to create the minimal production image
# FROM alpine:latest

# # Set the working directory
# WORKDIR /

# # Copy the compiled binary from the 'builder' stage
# COPY --from=builder /main /main

# # Expose port 8080 to the outside world
# EXPOSE 8080

# # Command to run the executable
# ENTRYPOINT ["/main"]

# Stage 1: The 'builder' stage
# CHANGE 1: Use a Debian-based image (glibc) instead of Alpine (musl)
# This matches your Ubuntu CI runner, so the patcher tool will run successfully.
FROM golang:1.24-bookworm AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application source code
COPY *.go ./

# Copy the time-freezing tool (built in CI)
COPY go_freeze_time_amd64 /lib/keploy/go_freeze_time_amd64

# Set permissions
RUN chmod +x /lib/keploy/go_freeze_time_amd64

# Run the binary to set up the time freezing environment
# THIS WILL NOW WORK because Debian has the glibc libraries the binary expects.
RUN /lib/keploy/go_freeze_time_amd64

# Build the Go application
# You can keep CGO_ENABLED=0 for a static binary, or use CGO_ENABLED=1. 
# Since we are switching the final image to Debian as well, CGO_ENABLED=0 is safest for portability.
RUN CGO_ENABLED=0 GOOS=linux go build -tags=faketime -o /main .

# Stage 2: The 'final' stage
# CHANGE 2: Use Debian Slim instead of Alpine to match the builder OS family
# It is slightly larger than Alpine but much more compatible with standard binaries.
FROM debian:bookworm-slim

# Set the working directory
WORKDIR /

# Copy the compiled binary from the 'builder' stage
COPY --from=builder /main /main

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
ENTRYPOINT ["/main"]