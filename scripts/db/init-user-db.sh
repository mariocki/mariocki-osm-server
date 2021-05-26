#!/bin/bash

createuser renderer
createdb -E UTF8 -O renderer ${PGDATABASE}
psql -c "ALTER USER renderer PASSWORD '${PGPASSWORD:-renderer}'"
psql -d gis -c "CREATE EXTENSION postgis;"
psql -d gis -c "CREATE EXTENSION hstore;"
psql -d gis -c "ALTER TABLE geometry_columns OWNER TO renderer;"
psql -d gis -c "ALTER TABLE spatial_ref_sys OWNER TO renderer;"
