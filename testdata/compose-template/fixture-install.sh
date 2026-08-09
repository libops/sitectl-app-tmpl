#!/bin/sh

set -eu

install -d -m 0755 /srv/app
printf '%s\n' 'sitectl application template fixture' > /srv/app/index.html
install -m 0755 /tmp/fixture-httpd.sh /usr/local/bin/fixture-httpd
rm -f /tmp/fixture-httpd.sh /tmp/fixture-install.sh
touch /installed
