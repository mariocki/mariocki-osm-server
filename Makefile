
maps: osm-server-maps
db: osm-server-db
kosmtik: osm-server-kosmtik
import: osm-server-import

osm-server-maps: osm-server-db osm-server-core $(shell find siteroot -type f | sed 's/ /\\ /g') Dockerfile.osm-server-maps 
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-db: Dockerfile.osm-server-db
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-core: osm-server-build-stage Dockerfile.osm-server-core 
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-build-stage: Dockerfile.osm-server-build-stage
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-import: osm-server-core Dockerfile.osm-server-import
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-kosmtik: Dockerfile.osm-server-kosmtik
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

pgadmin: osm-server-db
	docker compose build pgadmin
	touch $@

pghero: osm-server-db
	docker compose build pghero
	touch $@

.PHONY: all clean carto

all: osm-server-db osm-server-maps osm-server-import osm-server-kosmtik pghero pgadmin

clean:
	docker system prune -f
	
carto: $(shell find openstreetmap-carto -type f | sed 's/ /\\ /g')
	$(MAKE) -C openstreetmap-carto
