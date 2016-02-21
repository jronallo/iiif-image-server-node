###
Simple file resolver!
This could be changed to find images split across directories based on the id
or look up the path to the image in a database. In this case we know all the
images are going to be JP2s.
###

path = require 'path'
log = require('./index').log
config = require 'config'
resolver_base_path = config.get('resolver.base_path')

resolve_image_path = (id) ->
  filename = "#{id}.jp2"
  if resolver_base_path
    path.join resolver_base_path, filename
  else
    path.join __dirname, "/../images/#{filename}"

exports.resolve_image_path = resolve_image_path
