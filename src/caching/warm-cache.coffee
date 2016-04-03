_ = require 'lodash'
config = require 'config'
http = require 'http'
async = require 'async'
path = require 'path'
profiles = _.values(config.get('profile'))
clear_cache_for_id = require('./clear-cache').clear_cache_for_id
clear_cache_from_profile = require('./clear-cache').clear_cache_from_profile
log = require('../index').log

warm_cache = (req, res) ->
  identifier = req.params.id

  # warm_profile does the actual work for a single profile URL path.
  warm_profile = (url_part, callback) ->
    full_path = path.join req.headers.host, config.get('prefix'), identifier, url_part
    scheme = if req.connection.encrypted? then 'https' else 'http'
    full_url = "#{scheme}://#{full_path}"
    http.get(full_url, (res) ->
      if res.statusCode == 200
        callback()
      else
        callback(true)
    ).on 'error', (e) ->
      callback(true)

  process_profiles = ->
    async.each profiles, warm_profile, (err) ->
      if err
        # If there's an error anywhere along the way this is a failure.
        # TODO: Clean up any files that might have been created.
        res.status(400).send('unable to warm cache')
      else
        res.status(200).send(profiles)

  request_info_json = (id) ->
    # First we want to create the info.json
    info_json_path = path.join req.headers.host, config.get('prefix'), identifier, 'info.json'
    scheme = if req.connection.encrypted? then 'https' else 'http'
    info_json_url = "#{scheme}://#{info_json_path}"
    log.info "INFOJSONURL #{info_json_url}"
    http.get info_json_url, (response) ->
      console.log config.get('profile')
      if config.get('profile')
        process_profiles()
      else
        res.status(200).send(info_json_url)

  # Clear the cache completely before warming it again. Once it is cleared
  # then process the profiles async.
  clear_with = config.get('cache.warm.clear_with')
  if clear_with == 'id'
    clear_cache_for_id identifier, request_info_json
  else if clear_with == 'profile'
    clear_cache_from_profile identifier, request_info_json
  else # clear_with set to false so we don't clear and just warm
    request_info_json(req.params.id)

module.exports = warm_cache
