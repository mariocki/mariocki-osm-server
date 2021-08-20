#!/bin/bash

set -x

cd /app
bundle exec rails dev:cache
bundle exec rails s -p 3000 -b '0.0.0.0'
exit 0
