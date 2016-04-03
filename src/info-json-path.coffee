path = require 'path'
path_for_cache_file = require('./caching/path-for-cache-file')

info_json_path = (id) ->
  info_json_path_part = path.join id, 'info.json'
  path_for_cache_file(info_json_path_part)

module.exports = info_json_path
