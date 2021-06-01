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

## Bulk rendering
Connect to the maps server and run one of the lines shown below:
```
docker-compose up -d maps
docker exec -it mariocki-osm-server_maps_1 /bin/bash
```

UK

`render_list_geo.pl -f -z 6 -Z 13 -x -9.5 -X 2.72 -y 49.39 -Y 61.26 -m ajt`

London 51.5074/-0.1278

`render_list_geo.pl -f -z 14 -Z 18 -x -7.4 -X 0.57 -y 51.29 -Y 51.8 -m ajt`

manchester 53.4808/-2.2426

`render_list_geo.pl -f -z 14 -Z 16 -x -2.5 -X -1.99 -y 53.36 -Y 53.61 -m ajt`


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

mkdir -p vrt tif translated
for a in $(find cache -name *.tif); do

    fname=${a##*/}

    gdalbuildvrt vrt/${fname%.tif}.vrt $a

    gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 vrt/${fname%.tif}.vrt translated/${fname%.tif}

    mkdir -p contours/${fname%.tif}
    gdal_contour -q -i 10 -f "ESRI Shapefile" -a height translated/${fname%.tif} contours/${fname%.tif}
done

## https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
## pick a random contour.shp file from in the contour directory ... doesn't matter which.
shp2pgsql -p -I -g way -s 4326:3857 contours/N49E000/contour.shp contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB}

for a in $(find contours -name *.shp); do
    echo "Processing" $a >>contour.log
    shp2pgsql -a -e -g way -s 4326:3857 ${a} contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB}
done
```

And then add contours to your carto style as shown here https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik#Update_the_CSS_files

### Hillshading
Assuming you have followed the steps above for contours...
```
mkdir -p warpedtif hillshade

for a in tif/*.tif; do 
    gdalwarp -of GTiff -co "TILED=YES" -srcnodata 32767 -t_srs "+proj=merc +ellps=sphere +R=6378137 +a=6378137 +units=m" -rcs -order 3 -tr 30 30 -multi $a warpedtif/${a##*/};
done

for a in warpedtif/*.tif; do 
    gdaldem hillshade $a hillshade/${a##*/} -z 2;
done
```

Copy the hillshade folder to /var/lib/mod_tile/.

Run this and copy the contents of hillshade.mml into your project.mml
```
i=0
for a in $(find /var/lib/mod_tile/hillshade/*); do 
  echo { \"id\": \"hillshade-$i\", \"class\": \"hillshade\", \"geometry\": \"raster\", \"extent\": [-9.5, 49, 2.75, 62], \"srs-name\": \"900913\", \"srs\": \"+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over\", \"Datasource\": { \"file\": \"$a\", \"type\": \"gdal\" }, \"properties\": { \"minzoom\": 8 } }, >> hillshade.mml; 
  ((i=i+1))
done
```
