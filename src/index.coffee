express = require('express')
app = express()
_ = require 'lodash'
path = require 'path'
fs = require 'fs'
iiif = require 'iiif-image'
Informer = iiif.Informer
Extractor = iiif.Extractor
Parser = iiif.ImageRequestParser
InfoJSONCreator = iiif.InfoJSONCreator
tempfile = require 'tempfile'

cache = require('memory-cache')

# Simple file resolver
resolve_image_path = (id) ->
  path.join __dirname, "/../images/#{id}.jp2"

image_extraction = (res, url) ->
  # First we parse the URL to extract all the information we'll need from the
  # request to choose the correct image, extract information from it, and
  # create the requested image.
  parser = new Parser url
  params = parser.parse()
  image_path = resolve_image_path(params.identifier)

  # Usually you'd want to do some image information caching, but in this case
  # we'll just look up the information every request.

  # This will be the last method called once the extractor has created the
  # image to return.
  extractor_cb = (image) ->
    # TODO: better mimetype handling for more formats
    image_type = if @params.format == 'png' then 'image/png' else 'image/jpeg'
    res.setHeader 'Content-Type', image_type
    # TODO: If a String is returned then sendFile else return the buffer
    # Return the buffer sharp creates which means it does not have to be read
    # off the file system.
    res.send image
    # After we send the image we can cache it
    if !cache.get url
      image_path = tempfile(".#{params.format}")
      fs.writeFile image_path, image, (err) ->
        cache.put url, image_path

  # Once the informer finishes its work it calls this callback with the information.
  # The extractor then uses it to create the image.
  info_cb = (info) ->
    if !cache.get(params.identifier)
      cache.put params.identifier, info
    options =
      path: image_path
      params: params # from ImageRequestParser
      info: info
    extractor = new Extractor options, extractor_cb
    extractor.extract()

  # The informer runs first unless the info is in the cache
  cache_info = cache.get params.identifier
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

# Our javascript to start up the openseadragon viewer
app.get '/openseadragon-start.js', (req, res) ->
  osds = path.join __dirname, "/../app/openseadragon-start.js"
  res.sendFile(osds)

# Respond to a IIIF Image Information Request with JSON
app.get '*info.json', (req, res) ->
  url = req.url
  url_parts = url.split('/')
  id = url_parts[url_parts.length - 2]
  image_path = resolve_image_path(id)

  scheme = if req.connection.encrypted? then 'https' else 'http'
  server_info =
    id: "#{scheme}://#{req.headers.host}/#{id}"
    level: 1

  info_cb = (info) ->
    if !cache.get(id)
      cache.put id, info
    info_json_creator = new InfoJSONCreator info, server_info
    res.send info_json_creator.info_json

  cache_info = cache.get id
  if cache_info
    info_cb(_.cloneDeep cache_info)
  else
    informer = new Informer image_path, info_cb
    informer.inform()

# The actual image server.``
# This image server will only accept requests for jpg and png images.
app.get '*.(jpg|png)', (req, res) ->
  url = req.url
  cache_image_path = cache.get url
  # If the image is cached try to serve the cached image
  if cache_image_path
    # Check to see if the image exists
    fs.stat cache_image_path, (err, stats) ->
      # If there is an error delete the key from the cache, and
      # just run the image extraction like normal. Pass the response in
      # with the url which is all that is needed to respond.
      if err
        cache.del url
        image_extraction(res, url)
      else
        # A good cache hit so we serve the cached image.
        res.sendFile cache_image_path
  else
    image_extraction(res, url)

# Catch all route
app.get '*', (req, res) ->
  res.send('This route catches anything else that does not match.')

app.listen 3000, () ->
  console.log('Example IIIF image server listening on port 3000! Visit http://localhost:3000/index.html?id=trumpler14')
