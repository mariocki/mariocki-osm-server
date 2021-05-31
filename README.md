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

### Importing Data
Download a pbf from https://download.geofabrik.de/ and save it into the data folder and name it data.osm.pbf:

```
curl https://download.geofabrik.de/europe/liechtenstein-latest.osm.pbf -o ~/osm-maps/data/data.osm.pbf
```

[Optional]
Download the poly file and save it into the data folder and name it data.poly:

```
curl https://download.geofabrik.de/europe/liechtenstein.poly -o ~/osm-maps/data/data.poly
```

Then run this, this will create a postgis database server and start importing the data into the database.
```
docker-compose up --build import
```

Once the import has completed if you want to be able to view whats in the database folder then:
```
sudo adduser $SUDO_USER postgres
sudo chown -R .postgres ~/osm-maps/gis
sudo find ~/osm-maps/gis/ -type d -exec chmod g+rx {} \;
sudo find ~/osm-maps/gis/ -type f -exec chmod g+r {} \;
```

[Optional]
Create a postgres user on the sql box to stop some scripts from complaining.
You only need to do this once.
```
psql -U renderer -h localhost -d gis -c "CREATE USER postgres SUPERUSER;"
```

### Viewing your maps
To view your maps run this and open a browser at http://localhost:8080/.
```
docker-compose up -d maps
```

### Monitoring the database
[Optional]
If you want to monitor the database then run this and open a browser at http://localhost:8081/.
```
docker-compose up -d pghero
```

### Editing the map style
[Optional]
If you want to start editing the carto styles then run this and open a browser at http://localhost:6789/openstreetmap-carto/#4/0.00/0.00
```
docker-compose up kosmtik
```
More information about Kosmtik can be found here https://github.com/kosmtik/kosmtik

## Adding more countries to your database
Edit docker-compose.yml and remove the following line: `    command: --create`.
And then repeat the instructions under "Importing Data"

## Importing contour lines
:warning: This can take quite a long time to run. :warning:

Make sure you don't have any datafiles in the data folder (or else it'll try and re-import them :smile:):
```
mv ~/osm-maps/data/data.osm.pbf ~/osm-maps/data/data-old.osm.pbf 
mv ~/osm-maps/data/data.poly ~/osm-maps/data/data-old.poly
```

start and connect to the import server:
```
docker-compose up -d import
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
done

## https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
## pick a random contour.shp file from in the contour directory ... doesn't matter which.
shp2pgsql -p -I -g way -s 4326:3857 contours/N49E000/contour.shp contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1

for a in $(find contours -name *.shp); do
    shp2pgsql -a -e -g way -s 4326:3857 ${a} contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} >>contour.log 2>&1
done
```

And then add contours to your carto style as shown here https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik#Update_the_CSS_files
