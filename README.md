# Mariocki-osm-server

Containerised OpenStreetMap server based off the instructions found at : https://switch2osm.org/serving-tiles/manually-building-a-tile-server-debian-11/

:construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction: Work In Progreess :construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction::construction:
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

Create a new file named `.env` and copy this text into it:
```
## Environment ##
NODE_ENV=production

## Server ##
PORT=3000
HOST=localhost

## Setup jet-logger ##
JET_LOGGER_MODE=FILE
JET_LOGGER_FILEPATH=jet-logger.log
JET_LOGGER_TIMESTAMP=TRUE
JET_LOGGER_FORMAT=LINE

# Environment settings for importing to a Docker container database
PG_WORK_MEM=16MB
PG_MAINTENANCE_WORK_MEM=256MB
POSTGRES_HOST_AUTH_METHOD=trust
PGHOST=db
POSTGRES_USER=renderer
POSTGRES_PASSWORD=renderer
GIS_DB=gis

TZ=UTC
THREADS=4

# Azure maps subscription key
AZURE_MAP_KEY=

# Azure AD authentication
ENABLE_AZURE_AUTH=false
AZURE_CLIENT_ID=
AZURE_TENANT=
AZURE_SECRET=
AZURE_REDIRECT_URL=

# pgadmin
PGADMIN_DEFAULT_EMAIL=
PGADMIN_DEFAULT_PASSWORD=

#Bing maps
BING_KEY=

#OpenWeather Maps
OWM_MAP_KEY=

# openstreetmap-web
RAILS_MAX_THREADS=2
OSM_DB=openstreetmap
OSM_USER=openstreetmap

LOCAL_CHANGES_DB=local_changes
```
Most of these values you shouldn't need to change apart from maybe TZ and THREADS. If you do not have an Azure or Bing Maps subscriptions just leave them blank.

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
docker compose up --build import
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
docker compose up -d maps
```

### Editing the map style
[Optional]
If you want to start editing the carto styles then run this and open a browser at http://localhost:6789/openstreetmap-carto/#4/0.00/0.00
```
docker compose up kosmtik
```
More information about Kosmtik can be found here https://github.com/kosmtik/kosmtik

## Bulk rendering
Connect to the map server:
```
docker compose up -d maps
docker exec -it mariocki-osm-server_maps_1 /bin/bash
```

and run one of the lines shown below which will execute the command.
You can run `render_list_geo.pl -h` to view all the options.

Taken from: https://github.com/alx77/render_list_geo.pl/blob/master/render_list_geo.pl


UK

`render_list_geo.pl -z 6 -Z 16 -x -9.5 -X 2.72 -y 49.39 -Y 61.26 -m ajt`

London 51.5074/-0.1278

`render_list_geo.pl -f -z 14 -Z 18 -x -0.54 -X 0.31 -y 51.34 -Y 51.67 -m ajt`

manchester 53.4808/-2.2426

`render_list_geo.pl -f -z 14 -Z 16 -x -2.5 -X -1.99 -y 53.36 -Y 53.61 -m ajt`

## Bulk Expiry
Connect to the maps server:
```
docker compose up -d maps
docker exec -it mariocki-osm-server_maps_1 /bin/bash
```
and run one of the lines shown below which will execute the command.
You can run `expire_list_geo.pl -h` to view all the options.

manchester 
`expire_list_geo.pl -x -2.5 -X -1.99 -y 53.36 -Y 53.61 -z 13 -Z 18`

### Handy bbox coords
`-1219323.4752,6631065.0778,-598043.3093,7444355.0587` Eire

`-570831.7272,7157257.5805,-449143.9782,7271913.1229` IOM

`-307582.6018,6291684.6722,-218304.1528,6419487.3835` channel islands
	 
## Importing contour lines
### Using SRTM contour data
:warning: This can take quite a long time to run. :warning:

Make sure you don't have any datafiles in the data folder (or else it'll try and re-import them :smile:):
```
mv ~/osm-maps/data/data.osm.pbf ~/osm-maps/data/data-old.osm.pbf 
mv ~/osm-maps/data/data.poly ~/osm-maps/data/data-old.poly
```

start and connect to the import server:
```
docker compose up -d import
docker exec -it mariocki-osm-server_import_1 /bin/bash
```

run these steps:
```
## import contours
## taken from https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik

cd /data
mkdir -p cache vrt translated warped hillshade

# Download data if need-be (slow)
eio --cache_dir=cache seed --bounds -12.42 49.55 2.17 61.26 #uk+eire

for a in $(find cache -name *.tif); do
    fname=${a##*/}

    gdalbuildvrt vrt/${fname%.tif}.vrt $a

    gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 vrt/${fname%.tif}.vrt translated/${fname}

    for a in translated/*.tif; do 
        gdalwarp -of GTiff -co "TILED=YES" -srcnodata 32767 -t_srs "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over" -rcs -order 3 -tr 30 30 -multi $a warped/${a##*/};
    done

    mkdir -p contours/${fname%.tif}
    gdal_contour -q -i 10 -f "ESRI Shapefile" -a height warped/${fname} contours/${fname%.tif}

    # this next line is only required if you want to generate hillshade data.
    gdaldem hillshade warped/${fname} hillshade/${fname} -co "TILED=YES" -co "COMPRESS=DEFLATE" -combined -z 3;
done

## https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
## pick a random contour.shp file from in the contour directory ... doesn't matter which.
shp2pgsql -p -I -g way -s 4326:3857 contours/N49E000/contour.shp contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${GIS_DB}

for a in $(find contours -name *.shp); do
    echo "Processing" $a
    shp2pgsql -a -e -g way -s 4326:3857 ${a} contour | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${GIS_DB}
done
```

And then add contours to your carto style as shown here https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik#Update_the_CSS_files

### Using Ordnance Survey data (GB only)
Download from https://osdatahub.os.uk/downloads/open/Terrain50
Extract the zip file into a folder. Then exctract all the subfolders...
```
find . -name "*.zip" | while read filename; do unzip -o -d "`dirname "$filename"`" "$filename"; done;
```

Create the table and import the data.
```
## pick a random SHP file from one of the sub directories ... doesn't matter which.
shp2pgsql -p -I -g way -s 27700:3857 data/hp/HP40_line.shp contour_os | psql -h ${PGHOST} -U ${POSTGRES_USER} -d ${GIS_DB}


for a in `find . -name *.shp`; do shp2pgsql -a -e -g way -s 27700:3857 $a contour_os | psql -h  ${PGHOST} -U ${POSTGRES_USER} -d ${GIS_DB}; done
```

And then add contours to your carto style as shown here https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik#Update_the_CSS_files

### Hillshading
You will need to followed the steps above for generating contours from SRTM data.

Start and connect to the import server if not already done so:
```
docker compose up -d import
docker exec -it mariocki-osm-server_import_1 /bin/bash
```

Copy the hillshade folder to `/var/lib/mod_tile/`
```
mv /data/hillshade /var/lib/mod_tile/
```

Run this and copy the contents of hillshade.mml into your `openstreetmap-carto/project.mml` __after__ the landcover layers.

:warning: I use the JSON format MML file, if you use yaml you will need to change this.

```
i=0
for a in $(find /var/lib/mod_tile/hillshade/*); do 
  echo { \"id\": \"hillshade-$i\", \"class\": \"hillshade\", \"geometry\": \"raster\", \"extent\": [-9.5, 49, 2.75, 62], \"srs-name\": \"900913\", \"srs\": \"+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over\", \"Datasource\": { \"file\": \"$a\", \"type\": \"gdal\" }, \"properties\": { \"minzoom\": 8 } }, >> hillshade.mml; 
  ((i=i+1))
done
```

edit `openstreetmap-carto/style/landcover.mss` and add the following lines just before the line that says `#landcover-low-zoom[zoom < 10],`
```
.hillshade{
  raster-opacity:1;
  raster-comp-op: multiply;
  raster-scaling: bilinear;
}
```

## Updating via JOSM to local API
Run these in pgadmin to ensure we dont get any clashes in id's:
```
SELECT setval('changesets_id_seq', 1000000000, FALSE);
SELECT setval('current_nodes_id_seq', 99000000000, FALSE);
SELECT setval('current_ways_id_seq', 99000000000, FALSE);
SELECT setval('current_relations_id_seq', 99000000000, FALSE);

```

Then follow instructions as per https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md to create a user and configure OAuth.

## References

## Original step-by-step guide
* https://switch2osm.org/serving-tiles/manually-building-a-tile-server-debian-11/
## PGHero
* https://github.com/ankane/pghero

## Kosmtik
* https://github.com/kosmtik/kosmtik
## Bulk Rendering
* https://github.com/alx77/render_list_geo.pl/blob/master/render_list_geo.pl
## Contours
* https://wiki.openstreetmap.org/wiki/Contour_relief_maps_using_mapnik
* https://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg

If you get `AddGeometryColumn() - invalid SRID` during SHP import then run this on the db server:
```
psql -U renderer -d gis -f /usr/share/postgresql/13/contrib/postgis-3.2/spatial_ref_sys.sql
```

## Hillshading
* https://wiki.openstreetmap.org/wiki/Shaded_relief_maps_using_mapnik
* https://wiki.openstreetmap.org/wiki/HikingBikingMaps/HillShading
* https://tilemill-project.github.io/tilemill/docs/guides/terrain-data/
* https://gis.stackexchange.com/a/162390

