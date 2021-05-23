#!/bin/bash

set -x

# Error if no data is provided
if [ ! -f /data.osm.pbf ] && [ -z "$DOWNLOAD_PBF" ]; then
    echo "WARNING: No import file at /data.osm.pbf."
    exit
fi

if [ -n "$DOWNLOAD_PBF" ]; then
    echo "INFO: Download PBF file: $DOWNLOAD_PBF"
    wget "$WGET_ARGS" "$DOWNLOAD_PBF" -O /data.osm.pbf
    if [ -n "$DOWNLOAD_POLY" ]; then
        echo "INFO: Download PBF-POLY file: $DOWNLOAD_POLY"
        wget "$WGET_ARGS" "$DOWNLOAD_POLY" -O /data.poly
    fi
fi

cd /openstreetmap-carto
carto project.mml >mapnik.xml

# determine and set osmosis_replication_timestamp (for consecutive updates)
osmium fileinfo /data.osm.pbf >/var/lib/mod_tile/data.osm.pbf.info
osmium fileinfo /data.osm.pbf | grep 'osmosis_replication_timestamp=' | cut -b35-44 >/var/lib/mod_tile/replication_timestamp.txt
REPLICATION_TIMESTAMP=$(cat /var/lib/mod_tile/replication_timestamp.txt)

# initial setup of osmosis workspace (for consecutive updates)
sudo -u renderer openstreetmap-tiles-update-expire $REPLICATION_TIMESTAMP

# copy polygon file if available
if [ -f /data.poly ]; then
    sudo -u renderer cp /data.poly /var/lib/mod_tile/data.poly
fi

# Import data
sudo -u renderer osm2pgsql -H db -d gis --slim -G --hstore --tag-transform-script /openstreetmap-carto/openstreetmap-carto.lua --number-processes ${THREADS:-4} -S /openstreetmap-carto/openstreetmap-carto.style /data.osm.pbf ${1:---append}

# Create indexes
psql -h db -U ${PGUSER} -d gis -f /indexes.sql

#Import external data
sudo chown -R renderer: /home/renderer/src
sudo -u renderer python3 /openstreetmap-carto/scripts/get-external-data.py -c /openstreetmap-carto/external-data.yml -D /openstreetmap-carto/data -H db

# Register that data has changed for mod_tile caching purposes
touch /var/lib/mod_tile/planet-import-complete

exit 0
