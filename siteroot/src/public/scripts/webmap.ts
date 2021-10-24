import L from "leaflet";
import { BingProvider, GeoSearchControl } from "leaflet-geosearch";
import "leaflet-bing-layer";
import { KML } from "./L.KML";

const provider = new BingProvider({
    params: {
        key: process.env.BING_KEY,
    },
});

const map = L.map("map").setView([52, 0], 5);

map.addControl(
    GeoSearchControl({ provider, showMarker: false, autoClose: true })
);

// Base Layers
const osmBaseLayer = L.tileLayer("http://localhost:8080/tile/{z}/{x}/{y}.png", {
    maxZoom: 20,
    attribution:
        'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
    id: "base",
});

const rwyBaseLayer = L.tileLayer("http://localhost:8080/rwy/{z}/{x}/{y}.png", {
    maxZoom: 20,
    attribution:
        'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
    id: "base",
});

const Esri_WorldImagery = L.tileLayer(
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    {
        attribution:
            "Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community",
    }
);

const AzureMaps_Imagery = L.tileLayer(
    "https://atlas.microsoft.com/map/tile?api-version={apiVersion}&tilesetId=microsoft.imagery&x={x}&y={y}&zoom={z}&language={language}&subscription-key={subscriptionKey}",
    {
        attribution:
            "See https://docs.microsoft.com/en-US/rest/api/maps/renderv2/getmaptilepreview#uri-parameters for details.",
        apiVersion: "2.0",
        subscriptionKey: process.env.AZURE_MAP_KEY,
        language: "en-US",
    } as L.TileLayerOptions
);

// Overlay layers
const openAIP = L.tileLayer(
    "http://{s}.tile.maps.openaip.net/geowebcache/service/tms/1.0.0/openaip_basemap@EPSG%3A900913@png/{z}/{x}/{y}.{ext}",
    {
        attribution: '<a href="https://www.openaip.net/">openAIP Data</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-NC-SA</a>)',
        ext: "png",
        minZoom: 9,
        maxZoom: 14,
        tms: true,
        detectRetina: false,
        subdomains: "12",
    } as L.TileLayerOptions
);

const openSeaMap = L.tileLayer(
    "https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png",
    {
        attribution: 'Map data: &copy; <a href="http://www.openseamap.org">OpenSeaMap</a> contributors',
        minZoom: 9,
    }as L.TileLayerOptions
);

const openWeatherMapTemp = L.tileLayer(
    "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid={openWeatherMapsAPIkey}",
    {
        attribution: 'Map data: &copy; <a href="http://www.openweathermap.org">OpenWeatherMap</a> contributors',
        openWeatherMapsAPIkey: process.env.OWM_MAP_KEY
    } as L.TileLayerOptions
);

const AzureMaps_MicrosoftWeatherRadarMain = L.tileLayer(
    "https://atlas.microsoft.com/map/tile?api-version={apiVersion}&tilesetId=microsoft.weather.radar.main&x={x}&y={y}&zoom={z}&language={language}&subscription-key={subscriptionKey}",
    {
        attribution: "See https://docs.microsoft.com/en-US/rest/api/maps/renderv2/getmaptilepreview#uri-parameters for details.",
        apiVersion: "2.0",
        subscriptionKey: process.env.AZURE_MAP_KEY,
        language: "en-US",
    } as L.TileLayerOptions
);

const OS_Imagery = L.tileLayer.bing({ bingMapsKey: process.env.BING_KEY, imagerySet: "OrdnanceSurvey", culture: "en-GB"})

const nls10k = L.tileLayer('https://mapseries-tilesets.s3.amazonaws.com/os/britain10knatgrid/{z}/{x}/{y}.png', {
    minZoom: 8,
    maxZoom: 20,
    attribution: 'Historical Maps Layer, from the <a href="http://maps.nls.uk/projects/api/">NLS Maps API</a>'
});

map.addLayer(osmBaseLayer);
const baseMaps = {"Base":osmBaseLayer, "Railways": rwyBaseLayer, "ESRIWorldImagery": Esri_WorldImagery, "AzureImagery": AzureMaps_Imagery, "OS": OS_Imagery, "NLS-10k": nls10k }
const overlayMaps = { "OpenAIP": openAIP, "OpenSeaMap": openSeaMap, "OpenWeatherMap Temp": openWeatherMapTemp, "AzureWeather": AzureMaps_MicrosoftWeatherRadarMain }

L.control.layers(baseMaps, overlayMaps).addTo(map);

let kmlLayer;

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
                kmlLayer = new KML(kml);
                map.addLayer(kmlLayer);
            });
    }
}

map.on("zoomend", () => {
    document.getElementById("zoom").innerHTML = map.getZoom().toString();
});

map.on("moveend", () => {
    const latlon = map.getCenter();

    document.getElementById("latlon").innerHTML = `${latlon.lat.toFixed(
        4
    )}, ${latlon.lng.toFixed(4)}`;
});

document.querySelector("#kml").addEventListener("change", function () {
    const showKml = this.checked;
    setKMLLayer(showKml);
});
