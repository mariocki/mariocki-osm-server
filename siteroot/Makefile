.PHONY: all 

all: $(shell find src -type f | sed 's/ /\\ /g')
	$(RM) -rf dist/
	mkdir -p ./dist/ ./dist/pre-start/env/
	cp -aR src/public dist/
	cp -aR src/views dist/
	cp src/pre-start/env/.env dist/pre-start/env/
	tsc --build tsconfig.prod.json
	cp -aR node_modules/leaflet/dist/images src/public/stylesheets/
	cp node_modules/leaflet-geosearch/dist/geosearch.css src/public/stylesheets/
	cp node_modules/leaflet/dist/leaflet.css src/public/stylesheets/
	browserify dist/public/scripts/webmap.js -t [localenvify --envfile dist/pre-start/env/.env ] -o dist/public/scripts/webmap-browser.js
