#!/bin/sh

set -eu

response='sitectl application template fixture'
trap 'exit 0' INT TERM

while :; do
    # The pinned LibOps base image includes netcat-openbsd. Keep the integration
    # fixture dependency-free while serving enough HTTP for Compose, sitectl,
    # and Traefik health checks to exercise the generated project lifecycle.
    printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 36\r\nConnection: close\r\n\r\n%s' \
        "$response" | /usr/bin/nc -l -p 8080 -q 0 || true
done
