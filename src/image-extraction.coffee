resolve_image_path = require('./resolver').resolve_image_path
_ = require 'lodash'
tempfile = require 'tempfile'
fs = require 'fs'
iiif = require 'iiif-image'
Informer = iiif.InformerJp2Openjpeg

###
Choose which extractor you want to use:
opj => OpenJPEG => opj_decompress
kdu => Kakadu => kdu_expand
###
Extractor = iiif.Extractor('opj')

###
This function needs the response object and the incoming URL to parse the URL,
get information about the image, extract the requested image, and provide a
response to the client.
TODO: is it worth it to break this out when we have to pass so much in?
###

image_extraction = (res, url, params, info_cache, image_cache) ->
  image_path = resolve_image_path(params.identifier)

  # This will be the last callback called once the extractor has created the
  # image to return.
  extractor_cb = (image) ->
    # TODO: better mimetype handling for more formats
    image_type = if params.format == 'png' then 'image/png' else 'image/jpeg'
    res.setHeader 'Content-Type', image_type
    # TODO: If a String is returned then sendFile else return the buffer
    # Return the buffer sharp creates which means it does not have to be read
    # off the file system.
    res.send image
    # After we send the image we can cache it for a time.
    # TODO: We should cache scheme/protocol-relative URLs if the image server
    # can be used under both HTTP and HTTPS.
    if !image_cache.get url
      image_path = tempfile(".#{params.format}")
      fs.writeFile image_path, image, (err) ->
        image_cache.set url, image_path

  # Once the informer finishes its work it calls this callback with the information.
  # The extractor then uses the information to create the image.
  info_cb = (info) ->
    # First if the information we get back is not already in the information
    # cache we add it there.
    if !info_cache.get(params.identifier)
      info_cache.set params.identifier, info
    # We create the options that the Extractor expects
    options =
      path: image_path
      params: params # from ImageRequestParser
      info: info
    extractor = new Extractor options, extractor_cb
    extractor.extract()

  # If the information for the image is in the cache then we do not run the
  # informer and just skip right to the doing something with the information.
  cache_info = info_cache.get params.identifier
  if cache_info
    info_cb(_.cloneDeep cache_info)
  else
    informer = new Informer image_path, info_cb
    informer.inform()


exports.image_extraction = image_extraction
