fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
_ = require 'lodash'
path_for_cache_file = require('./path-for-cache-file')
log = require('../index').log
config = require 'config'

cache_info_json = (req, info_json) ->
  info_json_path = path.join '/', config.get('prefix'), req.params.id, 'info.json'
  info_json_cache_path = path_for_cache_file info_json_path
  info_json_dir = path.dirname info_json_cache_path
  mkdirp info_json_dir, (err) ->
    if !err

      # Make sure scaleFactors are in the correct order!!!
      # FIXME: Picking reduction factors reverses this so we have to ensure sort.
      info_json.tiles[0].scaleFactors = _.sortBy info_json.tiles[0].scaleFactors

      info_json_file = JSON.stringify info_json
      fs.writeFile info_json_cache_path, info_json_file, (err) ->
        if !err
          log.info {cache: 'info.json', op: 'write', url: req.url, ip: req.ip}, 'info.json cached'
        else
          console.log err

module.exports = cache_info_json
