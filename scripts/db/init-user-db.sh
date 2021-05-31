#!/bin/bash

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

"${psql[@]}" --dbname="$POSTGRES_DB" <<-EOSQL
  CREATE EXTENSION IF NOT EXISTS hstore;
EOSQL
