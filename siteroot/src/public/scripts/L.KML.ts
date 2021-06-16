/*
 * 
 * Copyright (c) 2011-2015, Pavel Shramov, Bruno Bergot - MIT licence
 */

import L from 'leaflet';
import 'esri-leaflet';
import { KMLIconOptions } from './L.KMLIcon';
import KMLMarker from './L.KMLMarker';

export interface KMLOptions {
    iconOptions: string;
    fill: boolean;
    fillColor: string;
}

const ParsedStyles = new Map<string, ParsedStyle>();

class ParsedStyle {
    constructor() {
        this.rotation = 0;
        this.fill = false;
        this.weight = 0;
        this.id = "";
        this.href = "";
        this.color = "";
        this.fillColor = "";
        this.opacity = 1.0;
        this.fillOpacity = 1.0;
        this.x = 0;
        this.y = 0;
        this.xunits = "pixels";
        this.yunits = "pixels";
        this.iconOptions = null;
    }

    rotation: number;
    fill: boolean;
    weight: number;
    id: string;
    href: string;
    color: string;
    fillColor: string;
    opacity: number;
    fillOpacity: number;
    x: number;
    y: number;
    xunits: string;
    yunits: string;

    iconOptions: KMLIconOptions;
}

export class KML extends L.FeatureGroup {
    _kml: Document;

    _layers: L.Layer[];

    _latLngs: L.LatLng[];

    constructor(kml: Document) {
        super();
        this._kml = kml;
        this._layers = new Array<L.Layer>(0);
        this._latLngs = new Array<L.LatLng>(0);

        if (kml) {
            this.addKML(kml);
        }
    }

    addKML(kml: Document): void {
        const layers = this.parseKML(kml.documentElement);
        if (!layers || !layers.length) return;
        for (let i = 0; i < layers.length; i++) {
            this.fire('addlayer', {
                layer: layers[i],
            });
            this.addLayer(layers[i]);
        }
        this._latLngs = this.getLatLngs(kml);
        this.fire('loaded');
    }

    /*
     * Return false if e's first parent Folder is not [folder]
     * - returns true if no parent Folders
     * TODO - WTAF!
     */
    _check_folder(folderElement: Element, folder: Element): boolean {
        let parent = folderElement.parentNode;
        while (parent && (parent as Element).tagName !== 'Folder') {
            parent = parent.parentNode;
        }
        return !parent || parent === folder;
    }

    parseKML(xml: Element): L.Layer[] {
        //console.log("parsing styles");
        this.parseStyles(xml); // checked
        //console.log("parsing style maps");
        this.parseStyleMap(xml); // checked
        const layers: L.Layer[] = new Array<L.Layer>(0);

        const folderElements: HTMLCollectionOf<Element> = xml.getElementsByTagName('Folder');
        for (let i = 0; i < folderElements.length; i++) {
            if (!this._check_folder(folderElements[i], (null as unknown) as Element)) { continue; }
            //console.log("parsing root folder");
            const layer: L.Layer = this.parseFolder(folderElements[i]);
            if (layer) { layers.push(layer); }
        }

        const placemarkElements: HTMLCollectionOf<Element> = xml.getElementsByTagName('Placemark');
        for (let j = 0; j < placemarkElements.length; j++) {
            if (!this._check_folder(placemarkElements[j], (null as unknown) as Element)) { continue; }
            //console.log("parsing root placemark");
            const layer: L.Layer = this.parsePlacemark(placemarkElements[j]);
            if (layer) { layers.push(layer); }
        }

        const groundOverlayElements: HTMLCollectionOf<Element> = xml.getElementsByTagName('GroundOverlay');
        for (let k = 0; k < groundOverlayElements.length; k++) {
            console.log("parsing root overlays");
            const layer: L.Layer = this.parseGroundOverlay(groundOverlayElements[k]);
            if (layer) { layers.push(layer); }
        }

        return layers;
    }

    parseStyles(xml: Element): void {
        const styleElements = xml.getElementsByTagName('Style');
        for (let i = 0, len = styleElements.length; i < len; i++) {
            const style: ParsedStyle = this.parseStyle(styleElements[i], {} as ParsedStyle);
            if (style) {
                ParsedStyles.set(`#${style.id}`, style);
            }
        }
    }

    // DONE
    parseStyle(xml: Element, existingStyle: ParsedStyle): ParsedStyle {
        let style: ParsedStyle = new ParsedStyle();

        const attributes = {
            color: true, width: true, Icon: true, href: true, hotSpot: true,
        };

        function _parse(xml: Node): ParsedStyle {
            const style: ParsedStyle = new ParsedStyle();

            for (let i = 0; i < xml.childNodes.length; i++) {
                const e: ChildNode = xml.childNodes[i];
                const key = (e as Element).tagName;
                if (!attributes[key]) { continue; }
                if (key === 'hotSpot') {
                    for (let j = 0; j < (e as Element).attributes.length; j++) {
                        style[(e as Element).attributes[j].name] = (e as Element).attributes[j].nodeValue;
                    }
                } else {
                    const value = e.childNodes[0].nodeValue;
                    if (value) {
                        if (key === 'color') {
                            style.opacity = parseInt(value.substring(0, 2), 16) / 255.0;
                            style.color = `#${value.substring(6, 8)}${value.substring(4, 6)}${value.substring(2, 4)}`;
                        } else if (key === 'width') {
                            style.weight = parseInt(value);
                        } else if (key === 'Icon') {
                            const iconStyle: ParsedStyle = _parse(e);
                            style.iconOptions = { iconUrl: iconStyle.href, anchorRef: { x: 0, y: 0 }, anchorType: { x: "pixels", y: "pixels" } };
                        } else if (key === 'href') {
                            style.href = value;
                        }
                    }
                }
            }

            return style;
        }

        const lineElement: HTMLCollectionOf<Element> = xml.getElementsByTagName('LineStyle');
        if (lineElement && lineElement[0]) {
            style = _parse(lineElement[0]);
        }

        const polyStyleElement: HTMLCollectionOf<Element> = xml.getElementsByTagName('PolyStyle');
        if (polyStyleElement && polyStyleElement[0]) {
            const polyStyle: ParsedStyle = _parse(polyStyleElement[0]);

            if (polyStyle.color) {
                style.fillColor = polyStyle.color;
            }
            if (polyStyle.opacity) {
                style.fillOpacity = polyStyle.opacity;
            }
        }

        const iconStyleElement: HTMLCollectionOf<Element> = xml.getElementsByTagName('IconStyle');
        if (iconStyleElement && iconStyleElement[0]) {
            const iconStyle: ParsedStyle = _parse(iconStyleElement[0]);
            //console.log("got this from icon style")
            //console.log(iconStyle);

            if (iconStyle.iconOptions) {
                iconStyle.iconOptions.shadowUrl = null ;
                iconStyle.iconOptions.anchorRef = { x: iconStyle.x, y: iconStyle.y };
                iconStyle.iconOptions.anchorType = { x: iconStyle.xunits, y: iconStyle.yunits };
            }

            if (typeof existingStyle === 'object' && typeof existingStyle.iconOptions === 'object') {
                L.Util.extend(iconStyle.iconOptions, existingStyle.iconOptions);
            }
            
            //console.log("existing iconoptions");
            //console.log(existingStyle.iconOptions);
            //console.log("new style");
            //console.log(iconStyle.iconOptions);

            style.iconOptions = iconStyle.iconOptions;

            //console.log("resultant style");
            //console.log(style);
        }

        const id: string = xml.getAttribute('id') || "";
        if (id && style) {
            style.id = id;
        }

        //console.log("full parsed style is");
        //console.log(style);

        return style;
    }

    // DONE
    parseStyleMap(xml: Element): void {
        const styleMapElements: HTMLCollectionOf<Element> = xml.getElementsByTagName('StyleMap');

        for (let i = 0; i < styleMapElements.length; i++) {
            const styleMapElement: Element = styleMapElements[i];
            let styleMapKey = "";
            let styleMapUrl = "";

            let keyElements: HTMLCollectionOf<Element> = styleMapElement.getElementsByTagName('key');
            if (keyElements && keyElements[0]) { styleMapKey = keyElements[0].textContent || ""; }
            keyElements = styleMapElement.getElementsByTagName('styleUrl');
            if (keyElements && keyElements[0]) { styleMapUrl = keyElements[0].textContent || ""; }

            if (styleMapKey === 'normal') {
                ParsedStyles.set(`#${styleMapElement.getAttribute('id')}`, ParsedStyles.get(styleMapUrl) || new ParsedStyle());
            }
        }
    }

    // DONE
    parseFolder(folderElement: Element): L.Layer {
        const layers: L.Layer[] = new Array<L.Layer>(0);

        const folderElements: HTMLCollectionOf<Element> = folderElement.getElementsByTagName('Folder');
        for (let i = 0; i < folderElements.length; i++) {
            if (!this._check_folder(folderElements[i], folderElement)) { continue; }
            //console.log("parsing sub folder " + folderElements[i].innerHTML);
            const layer: L.Layer = this.parseFolder(folderElements[i]);
            if (layer) { layers.push(layer); }
        }

        const placemarkElements: HTMLCollectionOf<Element> = folderElement.getElementsByTagName('Placemark');
        for (let j = 0; j < placemarkElements.length; j++) {
            if (!this._check_folder(placemarkElements[j], folderElement)) { continue; }
            //console.log("parsing sub pm " + placemarkElements[j].innerHTML);
            const layer: L.Layer = this.parsePlacemark(placemarkElements[j]);
            if (layer) { layers.push(layer); }
        }

        const groundOverlayElements: HTMLCollectionOf<Element> = folderElement.getElementsByTagName('GroundOverlay');
        for (let k = 0; k < groundOverlayElements.length; k++) {
            if (!this._check_folder(groundOverlayElements[k], folderElement)) { continue; }
            console.log("parsing sub go " + groundOverlayElements[k].innerHTML);
            const layer: L.Layer = this.parseGroundOverlay(groundOverlayElements[k]);
            if (layer) { layers.push(layer); }
        }

        if (!layers.length) {
            return null as unknown as L.Layer;
        }
        if (layers.length === 1) {
            return layers[0];
        }
        return new L.FeatureGroup(layers);

        // cant set name on layers???
        /*
           *const nameElements : HTMLCollectionOf<Element> = folderElement.getElementsByTagName('name');
           *if (nameElements.length && nameElements[0].childNodes.length) {
           *    layer.options.name = nameElements[0].childNodes[0].nodeValue;
           *}
           *return layer;
           */
    }

    // DONE
    parsePlacemark(placeMark: Element): L.Layer {
        let style: ParsedStyle = new ParsedStyle();

        const placemarkStyleUrlElement: HTMLCollectionOf<Element> = placeMark.getElementsByTagName('styleUrl');
        for (let i = 0; i < placemarkStyleUrlElement.length; i++) {
            const url = placemarkStyleUrlElement[i].childNodes[0].nodeValue || "";

            style = ParsedStyles.get(url) || new ParsedStyle();
        }

        const styleElement: Element = placeMark.getElementsByTagName('Style')[0];
        if (styleElement) {
            const inlineStyle = this.parseStyle(styleElement, style);
            if (inlineStyle) {
                style = inlineStyle;
            }
        }

        const multi = ['MultiGeometry', 'MultiTrack', 'gx:MultiTrack'];
        for (const h in multi) {
            const multiElement: HTMLCollectionOf<Element> = placeMark.getElementsByTagName(multi[h]);
            for (let i = 0; i < multiElement.length; i++) {
                const layer: L.Layer = this.parsePlacemark(multiElement[i]);
                this.addPlacePopup(placeMark, layer);
                return layer;
            }
        }

        const layers: L.Layer[] = [];

        const parse = ['LineString', 'Polygon', 'Point', 'Track', 'gx:Track'];
        for (const j in parse) {
            const tag = parse[j];
            const lineElement: HTMLCollectionOf<Element> = placeMark.getElementsByTagName(tag);
            for (let i = 0; i < lineElement.length; i++) {
                let layer: L.Layer;

                switch (tag) {
                    case 'LineString':
                        layer = this.parseLineString(lineElement[i], style);
                        break;
                    case 'Polygon':
                        console.log("parsing polygon");
                        layer = this.parsePolygon(lineElement[i], style);
                        break;
                    case 'Point':
                        layer = this.parsePoint(lineElement[i], style);
                        break;
                    case 'gx:Track':
                    case 'Track':
                        console.log("parsing track");
                        layer = this.parseTrack(lineElement[i], style);
                        break;
                    default:
                        console.log("unknown tag " + tag);
                        layer = null as unknown as L.Layer;
                        break;
                }
                if (layer) { layers.push(layer); }
            }
        }

        if (!layers.length) {
            return null as unknown as L.Layer;
        }
        let layer: L.Layer = layers[0];
        if (layers.length > 1) {
            layer = new L.FeatureGroup(layers);
        }

        this.addPlacePopup(placeMark, layer);
        return layer;
    }

    addPlacePopup(place: Element, layer: L.Layer): void {
        let el; let i; let j; let name; let
            descr = '';
        el = place.getElementsByTagName('name');
        if (el.length && el[0].childNodes.length) {
            name = el[0].childNodes[0].nodeValue;
        }
        el = place.getElementsByTagName('description');
        for (i = 0; i < el.length; i++) {
            for (j = 0; j < el[i].childNodes.length; j++) {
                descr += el[i].childNodes[j].nodeValue;
            }
        }

        if (name) {
            layer.bindPopup(`<h2>${name}</h2>${descr}`, { className: 'kml-popup' });
        }
    }

    // DONE
    parseCoords(line: Element): L.LatLng[] {
        const coordinateElements: HTMLCollectionOf<Element> = line.getElementsByTagName('coordinates');
        return this._read_coords(coordinateElements[0]);
    }

    // DONE
    parseLineString(line: Element, style: ParsedStyle): L.Polyline {
        const coords = this.parseCoords(line);
        if (!coords.length) {
            return null as unknown as L.Polyline;
        }

        return new L.Polyline(coords, style);
    }

    // DONE
    parseTrack(line: Element, style: ParsedStyle): L.Polyline {
        let gxCoordElements: HTMLCollectionOf<Element> = line.getElementsByTagName('gx:coord');
        if (gxCoordElements.length === 0) {
            gxCoordElements = line.getElementsByTagName('coord');
        }

        let coords: L.LatLng[] = new Array<L.LatLng>(0);
        for (let j = 0; j < gxCoordElements.length; j++) {
            coords = coords.concat(this._read_gxcoords(gxCoordElements[j]));
        }
        if (!coords.length) {
            return null as unknown as L.Polyline;
        }
        return new L.Polyline(coords, style);
    }

    // DONE
    parsePoint(line: Element, style :ParsedStyle): KMLMarker {
        const coordinateElements: HTMLCollectionOf<Element> = line.getElementsByTagName('coordinates');
        if (!coordinateElements.length) {
            return null as unknown as KMLMarker;
        }
        const latlonStrings: string[] = coordinateElements[0] && coordinateElements[0].childNodes[0] && coordinateElements[0].childNodes[0].nodeValue ? coordinateElements[0].childNodes[0].nodeValue.split(',') : new Array<string>(0);
        //console.log("creating marker with style...");
        //console.log("latlon: " + Number(latlonStrings[1]) + ", " + Number(latlonStrings[0]));
        //console.log(style.iconOptions)
        return new KMLMarker(new L.LatLng(Number(latlonStrings[1]), Number(latlonStrings[0])), style.iconOptions);
    }

    // DONE ish
    parsePolygon(line: Element, style: ParsedStyle): L.Polygon {
        let polys: L.LatLng[] = [];
        let inner: L.LatLng[] = [];

        const outerBoundaryElements: HTMLCollectionOf<Element> = line.getElementsByTagName('outerBoundaryIs');
        for (let i = 0; i < outerBoundaryElements.length; i++) {
            const coords: L.LatLng[] = this.parseCoords(outerBoundaryElements[i]);
            if (coords) {
                //console.log("poly concatting " + coords.length)
                polys = polys.concat(coords);
            }
        }

        const innerBoundaryElements: HTMLCollectionOf<Element> = line.getElementsByTagName('innerBoundaryIs');
        for (let i = 0; i < innerBoundaryElements.length; i++) {
            const coords: L.LatLng[] = this.parseCoords(innerBoundaryElements[i]);
            if (coords) {
                //console.log("inner concatting " + coords.length)
                inner = inner.concat(coords);
            }
        }

        //console.log("generated " + polys.length + " + " + inner.length + " polygons with style");
        //console.log(style);

        if (style.fillColor) {
            style.fill = true;
        }
        
        return new L.Polygon(polys.concat(inner), style);
    }

    // DONE
    getLatLngs(xml: Document): L.LatLng[] {
        const coordinateElements: HTMLCollectionOf<Element> = xml.getElementsByTagName('coordinates');
        let coords: L.LatLng[] = new Array<L.LatLng>(0);

        for (let j = 0; j < coordinateElements.length; j++) {
            // text might span many childNodes
            coords = coords.concat(this._read_coords(coordinateElements[j]));
        }
        return coords;
    }

    // DONE
    _read_coords(coordinateElement: Element): L.LatLng[] {
        let text = '';
        const coords: L.LatLng[] = new Array<L.LatLng>(0);

        for (let i = 0; i < coordinateElement.childNodes.length; i++) {
            text += coordinateElement.childNodes[i].nodeValue;
        }

        const splitText = text.split(/[\s\n]+/);
        for (let i = 0; i < splitText.length; i++) {
            const ll = splitText[i].split(',');
            if (ll.length < 2) {
                continue;
            }
            coords.push(new L.LatLng(Number(ll[1]), Number(ll[0])));
        }
        return coords;
    }

    // DONE
    _read_gxcoords(el: Element): L.LatLng[] {
        const coords: L.LatLng[] = new Array<L.LatLng>(0);
        const latlonText: string[] = el.firstChild && el.firstChild.nodeValue ? el.firstChild.nodeValue.split(' ') || new Array<string>(0) : new Array<string>(0);
        coords.push(new L.LatLng(Number(latlonText[1]), Number(latlonText[0])));
        return coords;
    }

    // DONE
    parseGroundOverlay(groundOverlayElement: Element): L.ImageOverlay {
        const latlonbox = groundOverlayElement.getElementsByTagName('LatLonBox')[0];
        const bounds = new L.LatLngBounds(
            [
                Number(latlonbox.getElementsByTagName('south')[0].childNodes[0].nodeValue),
                Number(latlonbox.getElementsByTagName('west')[0].childNodes[0].nodeValue),
            ], [
            Number(latlonbox.getElementsByTagName('north')[0].childNodes[0].nodeValue),
            Number(latlonbox.getElementsByTagName('east')[0].childNodes[0].nodeValue),
        ],
        );
        const attributes = { Icon: true, href: true, color: true };

        function _parse(xml: Element): ParsedStyle {
            const style: ParsedStyle = new ParsedStyle();
            let iconStyle: ParsedStyle= new ParsedStyle();

            for (let i = 0; i < xml.childNodes.length; i++) {
                const childNode: ChildNode = xml.childNodes[i];
                const key = (childNode as Element).tagName;
                if (!attributes[key]) { continue; }
                const value = childNode.childNodes[0].nodeValue;
                if (value) {
                    if (key === 'Icon') {
                        iconStyle = _parse(childNode as Element);
                        if (iconStyle.href) {
                            style.href = iconStyle.href;
                        }
                    } else if (key === 'href') {
                        style.href = value;
                    } else if (key === 'color') {
                        style.opacity = parseInt(value.substring(0, 2), 16) / 255.0;
                        style.color = `#${value.substring(6, 8)}${value.substring(4, 6)}${value.substring(2, 4)}`;
                    }
                }
            }
            return style;
        }

        const style: ParsedStyle = _parse(groundOverlayElement);
        if (latlonbox.getElementsByTagName('rotation')[0] !== undefined) {
            const rotation = latlonbox.getElementsByTagName('rotation')[0].childNodes[0].nodeValue || "0";
            style.rotation = parseFloat(rotation);
        }
        return new L.ImageOverlay(style.href, bounds, { opacity: style.opacity });
    }
}

/*
 *interface RotatedImageOverlayOptions extends ImageOverlayOptions {
 *    angle: number
 *}
 *
 * // Inspired by https://github.com/bbecquet/Leaflet.PolylineDecorator/tree/master/src
 *
 *class RotatedImageOverlay extends L.ImageOverlay{
 *    options: RotatedImageOverlayOptions = {
 *        angle: 0
 *    }
 *    _image: string;
 *    _bounds: LatLngBoundsExpression;
 *
 *    constructor(imageUrl: string, bounds: LatLngBoundsExpression, options: RotatedImageOverlayOptions) {
 *        super(imageUrl, bounds, options);
 *        this.options = options;
 *    }
 *
 *    _reset() {
 *        L.ImageOverlay.prototype._reset.call(this);
 *        this._rotate();
 *    }
 *
 *    _animateZoom(e) {
 *        L.ImageOverlay.prototype._animateZoom.call(this, e);
 *        this._rotate();
 *    }
 *
 *    _rotate() {
 *        if (L.DomUtil.TRANSFORM) {
 *            // use the CSS transform rule if available
 *            this._image.style[L.DomUtil.TRANSFORM] += ' rotate(' + this.options.angle + 'deg)';
 *        } else if (L.Browser.ie) {
 *            // fallback for IE6, IE7, IE8
 *            const rad = this.options.angle * (Math.PI / 180),
 *                costheta = Math.cos(rad),
 *                sintheta = Math.sin(rad);
 *            this._image.style.filter += ' progid:DXImageTransform.Microsoft.Matrix(sizingMethod=\'auto expand\', M11=' +
 *                costheta + ', M12=' + (-sintheta) + ', M21=' + sintheta + ', M22=' + costheta + ')';
 *        }
 *    }
 *
 *    getBounds() {
 *        return this._bounds;
 *    }
 *}
 */
