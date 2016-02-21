fs = require 'fs'
_ = require 'lodash'

config = require 'config'
jp2_binary = config.get 'jp2_binary'

iiif = require 'iiif-image'
InfoJSONCreator = iiif.InfoJSONCreator
Informer = iiif.Informer(jp2_binary)

resolve_image_path = require('./resolver').resolve_image_path

info_json_response = (req, res, info_cache) ->
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
      res.state(404).send('404')
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
        if !info_cache.get(id)
          info_cache.set id, info
        info_json_creator = new InfoJSONCreator info, server_info
        res.send info_json_creator.info_json

      # If the information is already in the cache we do not have to inspect the
      # image again.
      cache_info = info_cache.get id
      if cache_info
        info_cb(_.cloneDeep cache_info)
      else
        informer = new Informer image_path, info_cb
        informer.inform()

module.exports = info_json_response
