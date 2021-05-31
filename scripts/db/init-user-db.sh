#!/bin/bash

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

"${psql[@]}" --dbname="$POSTGRES_DB" <<-EOSQL
  CREATE EXTENSION IF NOT EXISTS hstore;

  CREATE TABLE "pghero_query_stats" (
    "id" bigserial primary key,
    "database" text,
    "user" text,
    "query" text,
    "query_hash" bigint,
    "total_time" float,
    "calls" bigint,
    "captured_at" timestamp
  );
  CREATE INDEX ON "pghero_query_stats" ("database", "captured_at");
EOSQL
