
$(document).ready(function() {
  var image_id, location, osd_config, viewer, qd={};
  window.location.search.substr(1).split("&").forEach(function(item) {
      var s = item.split("="),
          k = s[0],
          v = s[1] && decodeURIComponent(s[1]);
      (k in qd) ? qd[k].push(v) : qd[k] = [v]
  });

  image_id = qd.id[0]
  console.log(image_id);
  // location.query.id;
  console.log(image_id);
  osd_config = {
    id: 'openseadragon',
    prefixUrl: 'openseadragon/images/',
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
