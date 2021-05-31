# Mariocki-osm-server

Containerised OpenStreetMap server based off the instructions found at : https://switch2osm.org/serving-tiles/manually-building-a-tile-server-debian-11/

:construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction: Work In Progreess :construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction:
## Instructions
Clone this git repo to your local machine:

```
gh repo clone mariocki/mariocki-osm-server
```

Change directory to the repo and clone the openstreet-carto git repo(you should see an empty directory named openstreetmap-carto already exists)

```
cd mariocki-osm-server

gh repo clone gravitystorm/openstreetmap-carto
```

Create a folder in your home directory named "osm-maps/data":
```
mkdir -p ~/osm-maps/data
sudo useradd postgres -u 999
```

Download a pbf from https://download.geofabrik.de/ and save it into the data folder and name it data.osm.pbf:

```
curl https://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf -o ~/osm-maps/data/data.osm.pbf
```

[Optional]
Download the poly file and save it into the data folder and name it data.poly:

```
curl https://download.geofabrik.de/europe/liechtenstein.poly -o ~/osm-maps/data/data.poly
```

Then run:

```
docker-compose up --build import
```

If you want to be able to view whats in the database folder then:
```
sudo adduser $SUDO_USER postgres
sudo chown -R .postgres ~/osm-maps/gis
sudo find ~/osm-maps/gis/ -type d -exec chmod g+rx {} \;
sudo find ~/osm-maps/gis/ -type f -exec chmod g+r {} \;
```

This will create a postgis database server and start importing the data into the database.

Once the import has completed run:
```
docker-compose up maps
```

and open a browser at http://localhost:8080/.

If you want to monitor the database then run:
```
docker-compose up pghero
```
and open a browser at http://localhost:8081/.

If you want to start editing the carto styles then run:
```
docker-compose up kosmtik
```
and open a browser at http://localhost:6789/openstreetmap-carto/#4/0.00/0.00
More information about Kosmtik can be found here https://github.com/kosmtik/kosmtik

## Adding more countries to your database
Edit docker-compose.yml and remove the following line: `    command: --create`.

## Importing contour lines

:warning: This can take quite a long time to run. :warning:

Make sure you don't have any datafiles in the data folder (or else it'll try and re-import them :smile:):
```
mv ~/osm-maps/data/data.osm.pbf ~/osm-maps/data/data-old.osm.pbf 
mv ~/osm-maps/data/data.poly ~/osm-maps/data/data-old.poly
```

start and connect to the import server:
```
docker-compose up import
docker exec -it mariocki-osm-server_import_1 /bin/bash
```

run these steps:
```
## import contours
## taken from https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik
#
cd /data
# Download data if need-be (slow)
if [[ ! -f /data/srtm_30m.tif ]]; then
    ##eio clip -o /data/srtm_30m.tif --bounds -12.42 49.55 2.17 61.26 #uk+eire
    eio seed --bounds -12.42 49.55 2.17 61.26 #uk+eire
fi

mkdir -p vrt tif
rm -f contour.log
for a in $(find cache -name *.tif); do

    fname=${a##*/}

    echo "processing ${fname}" >>contour.log
    gdalbuildvrt vrt/${fname%.tif}.vrt $a >>contour.log 2>&1

    gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 vrt/${fname%.tif}.vrt tif/${fname%.tif}-t.tif >>contour.log 2>&1

    mkdir -p contours/${fname%.tif}
    gdal_contour -q -i 10 -f "ESRI Shapefile" -a height tif/${fname%.tif}-t.tif contours/${fname%.tif} >>contour.log 2>&1

    ## https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
    shp2pgsql -p -I -g way -s 4326:3857 contour.shp contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1
    psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "ALTER TABLE contour OWNER TO renderer;" >>contour.log 2>&1
    psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "CREATE INDEX contour_idx ON contour USING GIST (way);" >>contour.log 2>&1
    shp2pgsql -a -e -g way -s 4326:3857 contours/${fname%.tif}/contour.shp contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1

done
```

And then add contours to your carto style as shown here https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik#Update_the_CSS_files
