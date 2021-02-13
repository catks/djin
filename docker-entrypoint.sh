#!/bin/sh

set -e

bundle check || bundle install

./wait-for-it.sh gitserver:80 -t 10

exec bundle exec "$@"
