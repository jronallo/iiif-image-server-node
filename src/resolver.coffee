###
Simple file resolver!
This could be changed to find images split across directories based on the id
or look up the path to the image in a database. In this case we know all the
images are going to be JP2s.
###
path = require 'path'
resolve_image_path = (id) ->
  path.join __dirname, "/../images/#{id}.jp2"

exports.resolve_image_path = resolve_image_path
