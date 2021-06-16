import L from 'leaflet';
import KMLIcon from './L.KMLIcon';

interface KMLMarkerOptions extends L.MarkerOptions {
    icon : L.Icon.Default
}

export default class KMLMarker extends L.Marker {
    options: KMLMarkerOptions = {
      icon: new KMLIcon.Default(),
    }
}
