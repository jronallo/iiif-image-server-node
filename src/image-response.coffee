fs = require 'fs' # Used to test presence of files

# exported from main
log = require('./index').log
info_cache = require('./index').info_cache

config = require 'config' # Configuration from config directory

# The iiif-image pieces the image response needs. Note that image-extraction
# includes other extraction related modules.
iiif = require 'iiif-image'
Parser = iiif.ImageRequestParser
Validator = iiif.Validator
enrich_params = iiif.enrich_params
too_big = require('./helpers').too_big

# Helpers
resolve_source_image_path = require('./resolver').resolve_source_image_path
path_for_cache_file = require('./caching/path-for-cache-file')
# TODO: Allow for selecting a custom implementation of image_extraction
image_extraction = require('./image-extraction')

ttl = config.get('cache.image.ttl')

image_response = (req, res) ->
  ###
  In case there are query parameters we do not use #url for the full URL but
  instead use the Express method to get the path of the request only.
  ###
  url = req.path
  ###
  If the image exists just serve that up. This allows cached images
  to be used across instances of the application.
  ###
  image_file = path_for_cache_file(url)
  fs.stat image_file, (err, stats) ->
    if !err
      log.info {cache: 'image', found: 'hit', url: url, img: image_file}
      log.info {res: 'image', url: url, ip: req.ip}, 'response image'
      res.sendFile image_file
    else
      log.info {cache: 'image', found: 'miss', url: url, img: image_file}

      ###
      First we parse the URL to extract all the information we'll need from the
      request to choose the correct image.
      ###
      parser = new Parser url
      params = parser.parse()
      source_image_path = resolve_source_image_path(params.identifier)

      ###
      Check to see if the source image exists. If not return a 404.
      ###
      fs.stat source_image_path, (err, stats) ->
        if err
          log.info {res: '404', url: url, ip: req.ip}, '404'
          res.status(404).send('404')
        else
          ###
          We do a quick check whether the parameters of the request are valid
          before trying the extraction. If we do not have the image information
          yet, the check here is not able to check whether the request is
          completely valid.

          In cases where we do have the image information from the
          info_cache (say when we've already responded to an info.json request)
          we do a fuller validation of the request (is it in bounds?).
          ###

          # TODO: If the info.json is not in the info_cache then look on the
          #       file system for the info.json!!!

          image_info = info_cache.get params.identifier
          valid_request = if image_info
            # Since we have the image info we can enrich the params early on
            # and use the information to check for a valid request.
            params = enrich_params(params, image_info)
            validator = new Validator params, image_info
            # Besides checking for validity we also check whether this request
            # falls within the allowable size limits for the returned image.
            validity = validator.valid() && !too_big(params, image_info)
            if validity
              log.info {valid: true, test: 'info', url: url, ip: req.ip}, 'valid w/ info'
            else
              log.info {valid: false, test: 'info', url: url, ip: req.ip}, 'invalid w/ info'
            validity # return
          else
            validator = new Validator params
            validity = validator.valid_params()
            if validity
              log.info {valid: true, test: 'params', url: url, ip: req.ip}, 'valid with params'
            else
              log.info {valid: false, test: 'params', url: url, ip: req.ip}, 'invalid with params'
            validity # return

          # If we have a valid request we try to return an image.
          if valid_request
            # This is where most of the work happens!!!
            image_extraction(req, res, params)
          else
            log.info {res: '400', url: url, ip: req.ip}, '400'
            res.status(400).send('400 invalid')

module.exports = image_response
