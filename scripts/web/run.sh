#!/bin/bash

set -x

cd /app
touch tmp/caching-dev.txt
touch config/settings.local.yml

#rake i18n:js:export assets:precompile

bundle install

bundle exec rails s -p 3000 -b '0.0.0.0'

exit 0
