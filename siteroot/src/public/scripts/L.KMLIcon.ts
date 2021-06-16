/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import L from 'leaflet';

export default class KMLIcon extends L.Icon {

  constructor() {
    super({
      iconSize: [24, 24],
      iconAnchor: [16, 16],
      iconUrl: '',
    });
  }


    /*
     *_setIconStyles(img, name) {
     *    L.Icon.prototype._setIconStyles.apply(this, [img, name]);
     *}
     *
     *_createImg(src, el) {
     *    el = el || document.createElement('img');
     *    el.onload = this.applyCustomStyles.bind(this, el)
     *    el.src = src;
     *    return el;
     *}
     */

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    applyCustomStyles(img) : void {
      const { options } = this;
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const width = options.iconSize[0];
      const height = options.iconSize[1];

      this.options.popupAnchor = [0, (-0.83 * height)];
    }
}
