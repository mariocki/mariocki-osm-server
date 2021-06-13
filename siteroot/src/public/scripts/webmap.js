var L = require('leaflet');
var esri = require('esri-leaflet');

var map = L.map('map').setView([52, 0], 5);

// Base Layers
var osmBaseLayer = L.tileLayer("/tile/{z}/{x}/{y}.png", {
    maxZoom: 18,
    attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
    id: "base",
});
var Esri_WorldImagery = L.tileLayer(
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}", {
        attribution: "Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community",
    }
);
var AzureMaps_Imagery = L.tileLayer(
    "https://atlas.microsoft.com/map/tile?api-version={apiVersion}&tilesetId=microsoft.imagery&x={x}&y={y}&zoom={z}&language={language}&subscription-key={subscriptionKey}", {
        attribution: "See https://docs.microsoft.com/en-US/rest/api/maps/renderv2/getmaptilepreview#uri-parameters for details.",
        apiVersion: "2.0",
        subscriptionKey: process.env.AZURE_MAP_KEY,
        language: "en-US",
    }
);

// Overlay layers
var openAIP = L.tileLayer(
    "http://{s}.tile.maps.openaip.net/geowebcache/service/tms/1.0.0/openaip_basemap@EPSG%3A900913@png/{z}/{x}/{y}.{ext}", {
        attribution: '<a href="https://www.openaip.net/">openAIP Data</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-NC-SA</a>)',
        ext: "png",
        minZoom: 9,
        maxZoom: 14,
        tms: true,
        detectRetina: false,
        subdomains: "12",
    }
);
var openSeaMap = L.tileLayer(
    "https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png", {
        attribution: 'Map data: &copy; <a href="http://www.openseamap.org">OpenSeaMap</a> contributors',
    }
);
var AzureMaps_MicrosoftWeatherRadarMain = L.tileLayer(
    "https://atlas.microsoft.com/map/tile?api-version={apiVersion}&tilesetId=microsoft.weather.radar.main&x={x}&y={y}&zoom={z}&language={language}&subscription-key={subscriptionKey}", {
        attribution: "See https://docs.microsoft.com/en-US/rest/api/maps/renderv2/getmaptilepreview#uri-parameters for details.",
        apiVersion: "2.0",
        subscriptionKey: process.env.AZURE_MAP_KEY,
        language: "en-US",
    }
);


var basemapLayer;
var tileLayer;
var kmlLayer;

function setTileLayer(tilelayer) {
    if (tileLayer) {
        map.removeLayer(tileLayer);
    }

    switch (tilelayer) {
        case "OpenAIP":
            map.addLayer(openAIP);
            tileLayer = openAIP;
            break;
        case "OpenSeaMap":

            map.addLayer(openSeaMap);
            tileLayer = openSeaMap;
            break;
        case "AzureWeather":

            map.addLayer(AzureMaps_MicrosoftWeatherRadarMain);
            tileLayer = AzureMaps_MicrosoftWeatherRadarMain;
        default:
            break;
    }
}

function setBasemap(basemap) {
    if (basemapLayer) {
        map.removeLayer(basemapLayer);
    }

    switch (basemap) {
        case "ESRIWorldImagery":
            map.addLayer(Esri_WorldImagery);
            basemapLayer = Esri_WorldImagery;
            break;
        case "AzureImagery":
            map.addLayer(AzureMaps_Imagery);
            basemapLayer = AzureMaps_Imagery;
            break;
        default:
            map.addLayer(osmBaseLayer);
            basemapLayer = osmBaseLayer;
            break;
    }
}

function setKMLLayer(showKml) {
    if (kmlLayer) {
        map.removeLayer(kmlLayer);
    }

    if (showKml) {
        // Load kml file
        fetch("kml/MyPlaces.kml")
            .then((res) => res.text())
            .then((kmltext) => {
                // Create new kml overlay
                const parser = new DOMParser();
                const kml = parser.parseFromString(kmltext, "text/xml");
                kmlLayer = new L.KML(kml);
                map.addLayer(kmlLayer);
            });
    }
}

map.on("zoomend", function(ev) {
    document.getElementById("zoom").innerHTML = map.getZoom();
});

map.on("moveend", function(ev) {
    var latlon = map.getCenter();

    document.getElementById("latlon").innerHTML = parseFloat(latlon.lat).toFixed(4) + ", " + parseFloat(latlon.lng).toFixed(4);
});

document
    .querySelector("#basemaps")
    .addEventListener("change", function(e) {
        var basemap = e.target.value;
        setBasemap(basemap);
    });
document
    .querySelector("#tileLayer")
    .addEventListener("change", function(e) {
        var tilelayer = e.target.value;
        setTileLayer(tilelayer);
    });
document.querySelector("#kml").addEventListener("change", function() {
    var showKml = this.checked;
    setKMLLayer(showKml);
});

setBasemap("None");