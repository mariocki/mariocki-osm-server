import { tileLayer } from 'leaflet';

declare module 'leaflet' {
  namespace tileLayer {
    interface BingOptions extends TileLayerOptions {
      bingMapsKey?: string;
      imagerySet?: 'Aerial'|'AerialWithLabels'|'AerialWithLabelsOnDemand'|'CanvasDark'|'CanvasLight'|'CanvasGray'|'Road'|
        'RoadOnDemand'|'OrdnanceSurvey';
      culture?: string;
      style?: string;
    }

    export function bing(options: string|BingOptions): TileLayer;
  }
}
