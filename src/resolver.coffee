###
Simple file resolver!
This is how we find the JP2s.
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

nested_file_path_resolver = (id) ->
  nested_number = config.get('resolver.nested_number')
  first_n = id.substring 0, nested_number
  path.join base_path, first_n

pairtree_file_path_resolver = (id) ->
  pair_path = pairtree.path(id)
  path.join base_path, pair_path

resolve_directory = (id) ->
  clean_id = sanitize_id(id)
  type = config.get('resolver.type')
  if type == 'simple'
    base_path
  else if type == 'nested'
    nested_file_path_resolver(clean_id)
  else if type == 'pairtree'
    pairtree_file_path_resolver(clean_id)

resolve_image_path = (id) ->
  clean_id = sanitize_id(id)
  filename = "#{clean_id}.jp2"
  directory = resolve_directory(clean_id)
  path.join directory, filename




exports.resolve_image_path = resolve_image_path
exports.resolve_directory = resolve_directory
