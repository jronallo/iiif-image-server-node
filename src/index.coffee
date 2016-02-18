# The application frame work
express = require('express')
app = express()
# some libraries we need
_ = require 'lodash'
path = require 'path'
fs = require 'fs'
tempfile = require 'tempfile'
# All the IIIF tools
iiif = require 'iiif-image'
Informer = iiif.Informer
Extractor = iiif.Extractor
Parser = iiif.ImageRequestParser
InfoJSONCreator = iiif.InfoJSONCreator

###
We'll create two different memory caches. One will keep image information
for the life of the process and the other will be to cache images to the file
system for a specified amount of time.
###
NodeCache = require('node-cache')
info_cache = new NodeCache()
image_cache = new NodeCache stdTTL: 86400, checkperiod: 3600
image_cache.on 'del', (key, cached_image_path) ->
  console.log "Image deleted: #{key} #{cached_image_path}"
  fs.unlink cached_image_path

###
Simple file resolver!
This could be changed to find images split across directories based on the id
or look up the path to the image in a database. In this case we know all the
images are going to be JP2s.
###
resolve_image_path = (id) ->
  path.join __dirname, "/../images/#{id}.jp2"

###
This function needs the response object and the incoming URL to parse the URL,
get information about the image, extract the requested image, and provide a
response to the client.
###
image_extraction = (res, url, params) ->

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

# Serve a web page for an openseadragon viewer.
# http://localhost:3000/index.html?id=trumpler14
app.get '/index.html', (req, res) ->
  index = path.join __dirname, "/../app/index.html"
  res.sendFile(index)

# Javascript from openseadragon
app.get '/openseadragon.js', (req, res) ->
  osdjs = path.join __dirname, '/../node_modules/openseadragon/build/openseadragon/openseadragon.js'
  res.sendFile(osdjs)

# openseadragon control images
app.get '/openseadragon/images/:image', (req, res) ->
  osdf = path.join __dirname, "/../node_modules/openseadragon/build/openseadragon/images/#{req.params.image}"
  res.sendFile osdf

# Our JavaScript to start up the openseadragon viewer.
app.get '/openseadragon-start.js', (req, res) ->
  osds = path.join __dirname, "/../app/openseadragon-start.js"
  res.sendFile(osds)

# Respond to a IIIF Image Information Request with JSON
app.get '*info.json', (req, res) ->
  # Information requests are easy to parse.
  url = req.url
  url_parts = url.split('/')
  id = url_parts[url_parts.length - 2]
  image_path = resolve_image_path(id)

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

# The actual image server.
# This image server will only accept requests for jpg and png images.
app.get '*.(jpg|png)', (req, res) ->
  url = req.url

  # First we parse the URL to extract all the information we'll need from the
  # request to choose the correct image, extract information from it, and
  # create the requested image.
  parser = new Parser url
  params = parser.parse()

  # If the image is cached try to serve the cached image
  cache_image_path = image_cache.get url
  if cache_image_path
    # Check to see if the image exists
    fs.stat cache_image_path, (err, stats) ->
      # If there is an error delete the key from the cache, and
      # just run the image extraction like normal. Pass the response in
      # with the url which is all that is needed to respond.
      if err
        image_cache.del url
        image_extraction(res, url, params)
      else
        # A good cache hit so we serve the cached image.
        res.sendFile cache_image_path
  else # If the image is not cached run the extraction.

    ###
    TODO: Valid request format?
    Here we can do a quick check whether the format of the request is valid
    before trying the extraction. The check here would not be able to check
    whether the request is completely valid because we do not have the image
    information yet. In cases where we do have the image information from the
    cache we could do a fuller validation of the request (does it result in
    a 0 pixel image? Is the request out of bounds of the image?).
    ###

    image_extraction(res, url, params)

# TODO: Catch all route that probably ought to return a response code.
app.get '*', (req, res) ->
  res.send('This route catches anything else that does not match.')

app.listen 3000, () ->
  console.log('Example IIIF image server listening on port 3000! Visit http://localhost:3000/index.html?id=trumpler14')
