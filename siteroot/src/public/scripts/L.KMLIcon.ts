/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import L from 'leaflet';

export interface KMLIconOptions extends L.IconOptions {
  anchorRef: { x: number, y: number};
  anchorType: { x: string, y: string};
  iconUrl: string;
}

export default class KMLIcon extends L.Icon {
  options: KMLIconOptions;

  constructor(iconOptions: KMLIconOptions) {
    super(iconOptions);
    this.options = iconOptions
    this.options.iconSize = [20, 20];
    this.options.iconAnchor = [0, 0];
  }
  
  isArray = Array.isArray || function (obj) {
    return (Object.prototype.toString.call(obj) === '[object Array]');
  }

  _toPoint(x, y?, round?) {
    if (x instanceof L.Point) {
      return x;
    }
    if (this.isArray(x)) {
      return new L.Point(x[0], x[1]);
    }
    if (x === undefined || x === null) {
      return x;
    }
    if (typeof x === 'object' && 'x' in x && 'y' in x) {
      return new L.Point(x.x, x.y);
    }
    return new L.Point(x, y, round);
  }
  
  createIcon(oldIcon) {
    return this._createIcon('icon', oldIcon);
  }

  _createIcon(name, oldIcon) {
    const src = this._getIconUrl(name);

    if (!src) {
      if (name === 'icon') {
        throw new Error('iconUrl not set in Icon options (see the docs).');
      }
      return null;
    }

    const img = this._createImg(src, oldIcon && oldIcon.tagName === 'IMG' ? oldIcon : null);
    this._setIconStyles(img, name);

    return img;
  }

  _getIconUrl(name) {
    return this.options[name + 'Url'];
  }

  _setIconStyles(img, name) {
		const options = this.options;
		let sizeOption : L.PointExpression = options.iconSize
    
		if (typeof sizeOption === 'number') {
			sizeOption = [sizeOption, sizeOption];
		}

		const size = this._toPoint(sizeOption),
      anchor = this._toPoint(name === 'shadow' && options.shadowAnchor || options.iconAnchor || size && size.divideBy(2, true));

		img.className = 'leaflet-marker-' + name + ' ' + (options.className || '');

		if (anchor) {
			img.style.marginLeft = (-anchor.x) + 'px';
			img.style.marginTop  = (-anchor.y) + 'px';
		}

		if (size) {
			img.style.width  = size.x + 'px';
			img.style.height = size.y + 'px';
		}
  }

  _createImg(src, el) {
    el = el || document.createElement('img');
    el.onload = this.applyCustomStyles.bind(this, el)
    el.src = src;
    return el;
  }

	applyCustomStyles(img) {
		const options = this.options;
		const width = options.iconSize[0];
		const height = options.iconSize[1];

		this.options.popupAnchor = [0,(-0.83*height)];
		if (options.anchorType.x === 'fraction')
			img.style.marginLeft = (-options.anchorRef.x * width) + 'px';
		if (options.anchorType.y === 'fraction')
			img.style.marginTop  = ((-(1 - options.anchorRef.y) * height) + 1) + 'px';
		if (options.anchorType.x === 'pixels')
			img.style.marginLeft = (-options.anchorRef.x) + 'px';
		if (options.anchorType.y === 'pixels')
			img.style.marginTop  = (options.anchorRef.y - height + 1) + 'px';
	}  
}
