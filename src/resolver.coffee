###
Simple file resolver!
This could be changed to find images split across directories based on the id
or look up the path to the image in a database. In this case we know all the
images are going to be JP2s.
###

path = require 'path'
pairtree = require 'pairtree'
log = require('./index').log
config = require 'config'
resolver_base_path = config.get('resolver.base_path')

sanitize_id = (id) ->
  id.replace(/\./g, '')
  id

base_path = if resolver_base_path
    resolver_base_path
  else
    path.join __dirname, "/../images/"

simple_file_resolver = (id, filename) ->
  path.join base_path, filename

nested_file_resolver = (id, filename) ->
  nested_number = config.get('resolver.nested_number')
  first_n = id.substring 0, nested_number
  path.join base_path, first_n, filename

pairtree_file_resolver = (id, filename) ->
  pair_path = pairtree.path(id)
  path.join base_path, pair_path, filename

resolve_image_path = (id) ->
  clean_id = sanitize_id(id)
  filename = "#{clean_id}.jp2"
  image_path = if config.get('resolver.type') == 'simple'
    simple_file_resolver(clean_id, filename)
  else if config.get('resolver.type') == 'nested'
    nested_file_resolver(clean_id, filename)
  else if config.get('resolver.type') == 'pairtree'
    pairtree_file_resolver(clean_id, filename)
  image_path




exports.resolve_image_path = resolve_image_path
