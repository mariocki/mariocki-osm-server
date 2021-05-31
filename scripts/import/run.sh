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
    carto project.mml >mapnik.xml 2>/dev/null

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
    sudo -u renderer osm2pgsql -H ${PGHOST} -d ${POSTGRES_DB} --slim -G --hstore --tag-transform-script /openstreetmap-carto/openstreetmap-carto.lua --number-processes ${THREADS:-4} -S /openstreetmap-carto/openstreetmap-carto.style /data/data.osm.pbf ${1:---append}

    # Create indexes
    psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -f /indexes.psql

    #Import external data
    sudo chown -R renderer: /home/renderer/src
    sudo -u renderer python3 /openstreetmap-carto/scripts/get-external-data.py -c /openstreetmap-carto/external-data.yml -D /openstreetmap-carto/data -H db

    # Register that data has changed for mod_tile caching purposes
    touch /var/lib/mod_tile/planet-import-complete
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

##### import contours
##### taken from https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik
#####
###cd /data
##### Download data if need-be (slow)
###if [[ ! -f /data/srtm_30m.tif ]]; then
###    ##eio clip -o /data/srtm_30m.tif --bounds -12.42 49.55 2.17 61.26 #uk+eire
###    eio seed --bounds -12.42 49.55 2.17 61.26 #uk+eire
###fi
###
###mkdir -p vrt tif
###rm -f contour.log
###for a in $(find cache -name *.tif); do
###
###    fname=${a##*/}
###
###    echo "processing ${fname}" >>contour.log
###    gdalbuildvrt vrt/${fname%.tif}.vrt $a >>contour.log 2>&1
###
###    gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 vrt/${fname%.tif}.vrt tif/${fname%.tif}-t.tif >>contour.log 2>&1
###
###    mkdir -p contours/${fname%.tif}
###    gdal_contour -q -i 10 -f "ESRI Shapefile" -a height tif/${fname%.tif}-t.tif contours/${fname%.tif} >>contour.log 2>&1
###done
###
##### https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
###shp2pgsql -p -I -g way -s 4326:3857 contours/N49E000/contour.shp contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1
###
###for a in $(find contours -name *.shp); do
###    shp2pgsql -a -e -g way -s 4326:3857 ${a} contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1
###done
###
##### to correct a projection use this...
#### psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "ALTER TABLE contour ALTER COLUMN way TYPE geometry(Point,3857) USING ST_Transform(geom,3857);"
###
