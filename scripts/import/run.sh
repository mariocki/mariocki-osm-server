#!/bin/bash

set -x

# Clean /tmp
rm -rf /tmp/*

compgen -e | xargs -I @ bash -c 'printf "s|\${%q}|%q|g\n" "@" "$@"' | sed -f /dev/stdin /usr/bin/openstreetmap-tiles-update-expire-orig >/usr/bin/openstreetmap-tiles-update-expire
chmod a+x /usr/bin/openstreetmap-tiles-update-expire

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
    carto project.mml >mapnik.xml 2> >(grep -v "Styles do not match")

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

    # Import data
    sudo -u renderer osm2pgsql -H ${PGHOST} -d ${PGDATABASE} --slim -G --hstore --tag-transform-script /openstreetmap-carto/openstreetmap-carto.lua --number-processes ${THREADS:-4} -S /openstreetmap-carto/openstreetmap-carto.style /data/data.osm.pbf ${1:---append}

    # Create indexes
    psql -h ${PGHOST} -U ${PGUSER} -d ${PGDATABASE} -f /indexes.sql

    #Import external data
    sudo chown -R renderer: /home/renderer/src
    sudo -u renderer python3 /openstreetmap-carto/scripts/get-external-data.py -c /openstreetmap-carto/external-data.yml -D /openstreetmap-carto/data -H db

    # Register that data has changed for mod_tile caching purposes
    touch /var/lib/mod_tile/planet-import-complete
}

# Error if no data is provided
if [ -f /data/data.osm.pbf ] || [ ! -z "$DOWNLOAD_PBF" ]; then
    echo "Importing map data."
    import_map_data
else
    echo "no data files founds, doing nothing."
fi

echo "Done..."

sleep infinity

## import contours
## from https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik
#
## Download data if need-be (slow)
#if [[ ! -f /data/srtm_30m.tif ]]; then
#    eio clip -o /data/srtm_30m.tif --bounds -12.42 49.55 2.17 61.26 #uk+eire
#fi
#
## Calculate 10 m contours
#gdal_contour -i 10 -f "ESRI Shapefile" -a height /data/srtm_30m.tif /data/srtm_30m_contours_10m
#
## https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
#shp2pgsql -p -I -g way -s 4326:900913 /data/srtm_30m_contours_10m/contour.shp contour | psql -h ${PGHOST} -U ${PGUSER} -d ${PGDATABASE}
#shp2pgsql -d -e -g way -s 4326:900913 /data/srtm_30m_contours_10m/contour.shp contour | psql -h ${PGHOST} -U ${PGUSER} -d ${PGDATABASE}

exit 0
