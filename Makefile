

osm-server-maps: osm-server-db osm-server-core carto Dockerfile.osm-server-maps 
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	
osm-server-db: Dockerfile.osm-server-db
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .

osm-server-core: osm-server-build-stage Dockerfile.osm-server-core 
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .

osm-server-build-stage: Dockerfile.osm-server-build-stage
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .

osm-server-import: osm-server-core Dockerfile.osm-server-import
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .

osm-server-kosmtik: carto Dockerfile.osm-server-kosmtik
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .

pgadmin: osm-server-db
	docker compose build pgadmin

pghero: osm-server-db
	docker compose build pghero

.PHONY: all clean

all: osm-server-db osm-server-maps osm-server-import osm-server-kosmtik pghero pgadmin

clean:
	docker system prune -f
	
carto: $(shell find openstreetmap-carto -type f | sed 's/ /\\ /g')
	$(MAKE) -C openstreetmap-carto
