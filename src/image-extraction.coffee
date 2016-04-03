resolve_source_image_path = require('./resolver').resolve_source_image_path
_ = require 'lodash'
tempfile = require 'tempfile'
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
retrieve_cached_info_json = require './retrieve-cached-info-json'

# exported from main
log = require('./index').log
info_cache = require('./index').info_cache

# configuration from the config directory
config = require 'config'
jp2_binary = config.get 'jp2_binary'

iiif = require 'iiif-image'
Informer = iiif.Informer(jp2_binary)
Extractor = iiif.Extractor(jp2_binary)
Validator = iiif.Validator
InfoJSONCreator = iiif.InfoJSONCreator
path_for_cache_file = require('./path-for-cache-file')
too_big = require('./helpers').too_big
server_info = require './server-info'
cache_info_json = require './cache-info-json'
info_json_path = require './info-json-path'

###
This function needs the response object and the incoming URL to parse the URL,
get information about the image, extract the requested image, and provide a
response to the client.
###
image_extraction = (req, res, params) ->
  url = req.url
  source_image_path = resolve_source_image_path(params.identifier)

  # To begin we define some callbacks. extractor_cb and info_cb

  # This will be the last callback called once the extractor has created the
  # image to return.
  extractor_cb = (image) ->
    # TODO: better mimetype handling for more formats
    image_type = if params.format == 'png' then 'image/png' else 'image/jpeg'
    res.setHeader 'Content-Type', image_type

    ###
    Return the buffer sharp creates which means it does not have to be read
    off the file system.
    ###
    # TODO: If a String is returned then use sendFile else return the buffer.
    log.info {res: 'image', url: url, ip: req.ip}, 'response image'
    res.send image

    # After we send the image we can cache it. Assume if we get to this point
    # that the file did not already exist? TODO: check if this is a fine assumption.
    image_path = path_for_cache_file url
    dirname = path.dirname image_path
    mkdirp dirname, (err, made) ->
      if !err
        fs.writeFile image_path, image, (err) ->
          if !err
            log.info {cache: 'image', op: 'set', img: image_path, url: url}, 'image cached'

  ###
  Once the informer finishes its work it calls this callback sending it the
  information. Now that we have the info it checks to see if the request
  is valid. If it is valid then the extractor then uses the information to
  try to create the image. If the request is not valid then a 400 error is
  returned.
  ###
  info_cb = (info) ->
    # Now validate that the request is valid for this image
    validator = new Validator params, info
    # Besides checking for validity we also check whether this request
    # falls within the allowable size limits for the returned image.
    if validator.valid() && !too_big(params, info)
      log.info {valid: true, test: 'info', url: url, ip: req.ip}, 'valid w/ info'
      # We create the options that the Extractor expects
      options =
        path: source_image_path
        params: params # from ImageRequestParser
        info: info # from the Informer

      extractor = new Extractor options, extractor_cb
      extractor.extract()

      # cache the info.json in the info cache if it doesn't exist
      fs.stat info_json_path(req.params.id), (err, stats) ->
        if err
          info_json_creator = new InfoJSONCreator info, server_info(req, req.params.id)
          info_json = info_json_creator.info_json
          cache_info_json(req, info_json)
          
    else # not valid!
      log.info {valid: false, test: 'info', url: url, ip: req.ip}, 'invalid w/ info'
      log.info {res: '400', url: url, ip: req.ip}, '400'
      res.status(400).send('400')

  # If the information for the image is in the cache then we do not run the
  # informer and just skip right to the doing something with the information.
  retrieve_cached_info_json params.identifier, (info) ->
    if info
      info_cb(info)
    else
      informer = new Informer source_image_path, info_cb
      informer.inform()

module.exports = image_extraction
