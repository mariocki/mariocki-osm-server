import L from 'leaflet';
import KMLIcon, { KMLIconOptions } from './L.KMLIcon';

export default class KMLMarker extends L.Marker {

  constructor(latlng: L.LatLngExpression, style: KMLIconOptions) {
    super(latlng, style);
    const icon: KMLIcon = new KMLIcon(style);
    
    //console.log(icon);
    this.options.icon = icon;
  }
}
