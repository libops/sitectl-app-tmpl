#!/bin/sh

set -eu

install -d -m 0700 /secrets

if test ! -s /secrets/DB_ROOT_PASSWORD; then
  openssl rand -hex 32 > /secrets/DB_ROOT_PASSWORD
fi
if test ! -s /secrets/APP_DB_PASSWORD; then
  openssl rand -hex 32 > /secrets/APP_DB_PASSWORD
fi

chmod 0600 /secrets/DB_ROOT_PASSWORD /secrets/APP_DB_PASSWORD
