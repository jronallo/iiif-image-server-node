document.addEventListener("DOMContentLoaded", function(event) {
  var image_id, loc, loc_split, osd_config, viewer;

  loc = window.location.toString();
  loc_split = loc.split('/');
  // If there is a trailing slash then pop off the last trailing empty string
  // after the split.
  if (loc.lastIndexOf('/') === loc.length - 1) {
    loc_split.pop();
  }
  image_id = loc_split.pop();
  osd_config = {
    id: 'openseadragon',
    prefixUrl: '../openseadragon/images/',
    preserveViewport: true,
    visibilityRatio: 1,
    minZoomLevel: 1,
    defaultZoomLevel: 1,
    sequenceMode: false,
    tiles: [
      {
        scaleFactors: [1, 2, 4, 8, 16, 32],
        width: 1024
      }
    ],
    tileSources: []
  };

  server_url = window.location.protocol+'//'+window.location.hostname+(window.location.port ? ':'+window.location.port: '');

  // FIXME: This only works when the prefix is 'iiif'
  if (window.location.pathname.match(/^\/iiif\//)) {
    prefix = 'iiif/'
  } else {
    prefix = ''
  }
  full_url = server_url +'/'+ prefix + (encodeURIComponent(image_id)) + "/info.json";

  osd_config['tileSources'].push(full_url);
  return viewer = OpenSeadragon(osd_config);
});
