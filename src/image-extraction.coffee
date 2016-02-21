resolve_image_path = require('./resolver').resolve_image_path
_ = require 'lodash'
tempfile = require 'tempfile'
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'

# configuration from the config directory
config = require 'config'
jp2_binary = config.get 'jp2_binary'

iiif = require 'iiif-image'
Informer = iiif.Informer(jp2_binary)
Extractor = iiif.Extractor(jp2_binary)
Validator = iiif.Validator
path_for_image_cache_file = require './path-for-image-cache-file'

###
This function needs the response object and the incoming URL to parse the URL,
get information about the image, extract the requested image, and provide a
response to the client.
###

image_extraction = (res, url, params, info_cache, image_cache) ->
  image_path = resolve_image_path(params.identifier)

  # To begin we define some callbacks. extractor_cb and info_cb

  # This will be the last callback called once the extractor has created the
  # image to return.
  extractor_cb = (image) ->
    # TODO: better mimetype handling for more formats
    image_type = if params.format == 'png' then 'image/png' else 'image/jpeg'
    res.setHeader 'Content-Type', image_type

    # TODO: If a String is returned then use sendFile else return the buffer.
    # Return the buffer sharp creates which means it does not have to be read
    # off the file system.
    res.send image
    # After we send the image we can cache it for a time.
    if !image_cache.get url
      image_path = path_for_image_cache_file url
      dirname = path.dirname image_path
      mkdirp dirname, (err, made) ->
        if !err
          fs.writeFile image_path, image, (err) ->
            if !err
              image_cache.set url, image_path
              console.log "cached: #{image_path}"

  ###
  Once the informer finishes its work it calls this callback sending it the
  information. Now that we have the info it checks to see if the request
  is valid. If it is valid then the extractor then uses the information to
  try to create the image. If the request is not valid then a 400 error is
  returned.
  ###
  info_cb = (info) ->
    # First if the information we get back is not already in the information
    # cache we add it there.
    if !info_cache.get(params.identifier)
      info_cache.set params.identifier, info
    validator = new Validator params, info
    if validator.valid()
      # We create the options that the Extractor expects
      options =
        path: image_path
        params: params # from ImageRequestParser
        info: info # from the Informer

      extractor = new Extractor options, extractor_cb
      extractor.extract()
    else # not valid!
      res.status(400).send('400')

  # If the information for the image is in the cache then we do not run the
  # informer and just skip right to the doing something with the information.
  cache_info = info_cache.get params.identifier
  if cache_info
    info_cb(_.cloneDeep cache_info)
  else
    informer = new Informer image_path, info_cb
    informer.inform()

module.exports = image_extraction
