#!/bin/sh

set -eu

if test ! -f .env; then
  cp sample.env .env
fi
