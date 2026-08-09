#!/bin/sh

set -eu

attempt=0
until test -f /installed; do
  attempt=$((attempt + 1))
  if test "$attempt" -ge 150; then
    echo 'Application did not become ready for database migration within 5 minutes' >&2
    exit 1
  fi
  sleep 2
done
