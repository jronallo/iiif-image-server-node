_ = require 'lodash'
config = require 'config'
http = require 'http'
async = require 'async'
path = require 'path'
profiles = _.values(config.get('profile'))
clear_cache_for_id = require('./clear-cache').clear_cache_for_id
clear_cache_from_profile = require('./clear-cache').clear_cache_from_profile

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

  # Clear the cache completely before warming it again. Once it is cleared
  # then process the profiles async.

  clear_cache_for_id identifier, process_profiles
  # clear_cache_from_profile identifier, process_profiles



module.exports = warm_cache
