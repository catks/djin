#!/bin/sh

set -e

bundle check || bundle install

exec bundle exec "$@"
