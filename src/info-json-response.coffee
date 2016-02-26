fs = require 'fs'
_ = require 'lodash'
path = require 'path'
mkdirp = require 'mkdirp'

log = require('./index').log
info_cache = require('./index').info_cache

config = require 'config'
jp2_binary = config.get 'jp2_binary'

iiif = require 'iiif-image'
InfoJSONCreator = iiif.InfoJSONCreator
Informer = iiif.Informer(jp2_binary)

resolve_image_path = require('./resolver').resolve_image_path
path_for_cache_file = require('./path-for-cache-file')

info_json_response = (req, res) ->
  ###
  Information requests are easy to parse, so we just take the next to the
  last element to make our id. Note that this image server does not
  decodeURIComponent as our implementation of a file resolver in
  resolve_image_path is not robust enough to defend against a directory
  traversal attack.
  ###
  url = req.url
  url_parts = url.split('/')
  id = url_parts[url_parts.length - 2]
  image_path = resolve_image_path(id)

  ###
  Check to see if the image exists. If not return a 404. If the image exists
  return the information about the image.
  ###
  fs.stat image_path, (err, stats) ->
    if err
      log.info {res: '404', url: url, ip: req.ip}, '404'
      res.status(404).send('404')
    else
      # In order to create an IIIF information response we need just a little more
      # data from the server than the Informer already provides for the images.
      scheme = if req.connection.encrypted? then 'https' else 'http'
      server_info =
        id: "#{scheme}://#{req.headers.host}/#{id}"
        level: 1

      # Once we have the information from the image we can cache it if it is not
      # already cached and then create the information JSON response and send it.
      info_cb = (info) ->
        # First we cache the info in memory since it might get used again soon.
        if !info_cache.get(id)
          info_cache.set id, info
          log.info {cache: 'info', op: 'set', url: url, ip: req.ip}, 'info cached'
        info_json_creator = new InfoJSONCreator info, server_info
        # If the request asks for ld+json we return with the
        # same content-type. Otherwise we can just return
        # application/json be default.
        if req.get('Accept') && req.get('Accept').match /application\/ld\+json/
          res.set('Content-Type', 'application/ld+json')
        log.info {res: 'info', url: url, ip: req.ip}, 'response info'
        info_json = info_json_creator.info_json
        res.send info_json
        console.log info_json
        info_json_path = path_for_cache_file url
        info_json_dir = path.dirname info_json_path
        mkdirp info_json_dir, (err) ->
          if !err
            info_json_file = JSON.stringify info_json
            console.log info_json_path
            fs.writeFile info_json_path, info_json_file, (err) ->
              if !err
                log.info {cache: 'info.json', op: 'write', url: url, ip: req.ip}, 'info.json cached'
              else
                console.log err


      # If the information is already in the cache we do not have to inspect the
      # image again.
      cache_info = info_cache.get id
      if cache_info
        log.info {cache: 'info', found: 'hit', url: req.url, ip: req.ip}
        info_cb(_.cloneDeep cache_info)
      else
        log.info {cache: 'info', found: 'miss', url: req.url, ip: req.ip}
        informer = new Informer image_path, info_cb
        informer.inform()

module.exports = info_json_response
