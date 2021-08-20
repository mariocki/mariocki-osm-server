#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

BASE_DIR=/var/lib/mod_tile
CHANGE_FILE=$BASE_DIR/changes.osc.gz

compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /usr/local/bin/openstreetmap-tiles-update-expire-orig >/usr/local/bin/openstreetmap-tiles-update-expire
chmod a+x /usr/local/bin/openstreetmap-tiles-update-expire

import_map_data() {
    if [ -n "$DOWNLOAD_PBF" ]; then
        echo "INFO: Download PBF file: $DOWNLOAD_PBF"
        wget "$WGET_ARGS" "$DOWNLOAD_PBF" -O /data/data.osm.pbf
        if [ -n "$DOWNLOAD_POLY" ]; then
            echo "INFO: Download PBF-POLY file: $DOWNLOAD_POLY"
            wget "$WGET_ARGS" "$DOWNLOAD_POLY" -O /data/data.poly
        fi
    fi

    cd /openstreetmap-carto
    carto project.mml >mapnik.xml 2>/dev/null

    if [ "${1:---append}" == "--create" ]; then
        # determine and set osmosis_replication_timestamp (for consecutive updates)
        osmium fileinfo /data/data.osm.pbf >/var/lib/mod_tile/data.osm.pbf.info
        osmium fileinfo /data/data.osm.pbf | grep 'osmosis_replication_timestamp=' | cut -b35-44 >/var/lib/mod_tile/replication_timestamp.txt
        REPLICATION_TIMESTAMP=$(cat /var/lib/mod_tile/replication_timestamp.txt)

        # initial setup of osmosis workspace (for consecutive updates)
        sudo -u renderer openstreetmap-tiles-update-expire $REPLICATION_TIMESTAMP

        # copy polygon file if available
        if [ -f /data/data.poly ]; then
            sudo -u renderer cp /data/data.poly /var/lib/mod_tile/data.poly
        fi
    fi

    osmosis --td host="${PGHOST}" database="${OSM_DB}" user="${OSM_USER}" validateSchemaVersion="no"

    # Import data into OSM
    osmosis --rbf file="/data/data.osm.pbf" workers=${THREADS:-4} --wd host="${PGHOST}" database="${OSM_DB}" user="${OSM_USER}" validateSchemaVersion="no"

    # generate initial change file from OSM
    osmosis --rdc host="${PGHOST}" database="${OSM_DB}" user="${OSM_USER}" validateSchemaVersion="no" --simplify-change --wxc ${CHANGE_FILE}

    # import change file to gis
    osm2pgsql -H ${PGHOST} -d ${POSTGRES_DB} -U ${POSTGRES_USER} --slim -G --hstore --tag-transform-script /openstreetmap-carto/openstreetmap-carto.lua --number-processes ${THREADS:-4} -S /openstreetmap-carto/openstreetmap-carto.style ${CHANGE_FILE} ${1:---append}

    if [ "${1:---append}" == "--create" ]; then
        # Create indexes
        psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -f /indexes.psql

        # create rail_routes table and SP
        psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -f /create_rail_routes.psql
        psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -f /create_update_rail_routes.psql

        #Import external data
        mkdir -p /home/renderer/src
        sudo chown -R renderer: /home/renderer/src
        python3 /openstreetmap-carto/scripts/get-external-data.py -c /openstreetmap-carto/external-data.yml -D /openstreetmap-carto/data -H ${PGHOST} -d ${POSTGRES_DB} -U ${POSTGRES_USER}
    fi
}

chown -R renderer /var/lib/mod_tile
if [ -f /data/data.osm.pbf ] || [ ! -z "$DOWNLOAD_PBF" ]; then
    echo "Importing map data."
    import_map_data $1
else
    echo "no data files founds, doing nothing."
fi

echo "Done..."

sleep infinity

exit 0

##### import contours (Ordnance Survey GB Only)
#####
shp2pgsql -p -I -g way -s 27700:3857 /data/contours/data/hp/HP40_line.shp contour_os | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1

for a in `find /data/contours/data/ -name *.shp`; do 
    shp2pgsql -a -e -g way -s 27700:3857 $a contour_os | psql -h  ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB}; 
done

