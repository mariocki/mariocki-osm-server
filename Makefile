
.PHONY: all clean carto

all: osm-server-db osm-server-maps osm-server-import osm-server-kosmtik pghero pgadmin

maps: osm-server-maps
db: osm-server-db
kosmtik: osm-server-kosmtik
import: osm-server-import

osm-server-maps: osm-server-db osm-server-core $(shell find siteroot scripts/maps configs/maps -type f | sed 's/ /\\ /g') Dockerfile.osm-server-maps 
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-db: Dockerfile.osm-server-db $(shell find patches scripts/db configs/db -type f | sed 's/ /\\ /g')
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-core: Dockerfile.osm-server-core $(shell find configs/core -type f | sed 's/ /\\ /g')
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-import: osm-server-core Dockerfile.osm-server-import $(shell find scripts/import -type f | sed 's/ /\\ /g')
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

osm-server-kosmtik: Dockerfile.osm-server-kosmtik $(shell find patches scripts/kosmtik configs/kosmtik -type f | sed 's/ /\\ /g')
	docker build -f Dockerfile.$@ -t mariocki/$@:latest -t mariocki/$@:$(shell date +%FT%H%M%S) .
	touch $@

pgadmin: osm-server-db
	docker compose build pgadmin
	touch $@

pghero: osm-server-db
	docker compose build pghero
	touch $@

clean:
	docker system prune -f
	
carto: $(shell find openstreetmap-carto -type f | sed 's/ /\\ /g')
	$(MAKE) -C openstreetmap-carto
