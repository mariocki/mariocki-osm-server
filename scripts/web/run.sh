#!/bin/bash

set -x

cd /app
touch tmp/caching-dev.txt
bundle exec rails s -p 3000 -b '0.0.0.0'
exit 0
