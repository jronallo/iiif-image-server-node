fs = require 'fs'

log = require('./index').log

config = require 'config'
jp2_binary = config.get 'jp2_binary'

iiif = require 'iiif-image'
InfoJSONCreator = iiif.InfoJSONCreator
Informer = iiif.Informer(jp2_binary)

info_cache = require('./index').info_cache
resolve_source_image_path = require('./resolver').resolve_source_image_path
retrieve_cached_info_json = require './caching/retrieve-cached-info-json'
server_info = require './server-info'
cache_info_json = require './caching/cache-info-json'

info_json_response = (req, res) ->
  ###
  Information requests are easy to parse, so we just take the next to the
  last element to make our id. Note that this image server does not
  decodeURIComponent as our implementation of a file resolver in
  resolve_source_image_path is not robust enough to defend against a directory
  traversal attack.
  ###
  url = req.path
  url_parts = url.split('/')
  id = url_parts[url_parts.length - 2]
  source_image_path = resolve_source_image_path(id)

  ###
  Check to see if the image exists. If not return a 404. If the image exists
  return the information about the image.
  ###
  fs.stat source_image_path, (err, stats) ->
    if err
      log.info {res: '404', url: url, ip: req.ip}, '404'
      res.status(404).send('404')
    else
      # Once we have the information from the image we can cache it if it is not
      # already cached and then create the information JSON response and send it.
      info_cb = (info) ->
        # First create the response
        info_json_creator = new InfoJSONCreator info, server_info(req, id)
        log.info {res: 'info', url: url, ip: req.ip}, 'response info.json'
        info_json = info_json_creator.info_json
        info_json.profile.push {formats: ['jpg']}
        # Now immediately send the response
        res.send info_json

        # Set the info_cache
        info_cache.set id, info_json
        log.info {cache: 'info', op: 'set', url: url, ip: req.ip}, 'info cached'

        # Now we save it to the filesystem
        cache_info_json(req, info_json)

      # First we set some headers we will need in every case.
      # If the request asks for ld+json we return with the
      # same content-type. Otherwise we can just return
      # application/json be default.
      if req.get('Accept') && req.get('Accept').match /application\/ld\+json/
        res.set('Content-Type', 'application/ld+json')

      # If the information is already in the memory cache or on the file system we do
      # not have to inspect the image again.
      retrieve_cached_info_json id, (info) ->
        if info
          log.info {cache: 'info', found: 'hit', url: url, ip: req.ip}
          res.send info
        else
          log.info {cache: 'info', found: 'miss', url: url, ip: req.ip}
          informer = new Informer source_image_path, info_cb
          informer.inform()

module.exports = info_json_response
