document.addEventListener("DOMContentLoaded", function(event) {
  var image_id, loc, osd_config, viewer;

  loc = window.location.toString();
  image_id = loc.split('/').pop();
  console.log("image_id: "+image_id);
  osd_config = {
    id: 'openseadragon',
    prefixUrl: '../openseadragon/images/',
    preserveViewport: true,
    visibilityRatio: 1,
    minZoomLevel: 1,
    defaultZoomLevel: 1,
    sequenceMode: true,
    tiles: [
      {
        scaleFactors: [1, 2, 4, 8, 16, 32],
        width: 1024
      }
    ],
    tileSources: []
  };
  server_url = window.location.protocol+'//'+window.location.hostname+(window.location.port ? ':'+window.location.port: '');
  full_url = server_url +'/'+ (encodeURIComponent(image_id)) + "/info.json";
  osd_config['tileSources'].push(full_url);
  return viewer = OpenSeadragon(osd_config);
});
