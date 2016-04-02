fs = require 'fs'
info_cache = require('./index').info_cache
info_json_path = require './info-json-path'
log = require('./index').log

retrieve_cached_info_json = (id, callback) ->
  if info_cache.get id
    log.info "info.json from memory"
    callback(info_cache.get id)
  else
    # check if the file exists and if it doesn't return null
    fs.readFile info_json_path(id), (err, data) ->
      if err
        log.info 'info.json not in file'
        callback(null)
      else
        log.info 'info.json from file'
        callback(JSON.parse data)

module.exports = retrieve_cached_info_json
