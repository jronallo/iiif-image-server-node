# The application frame work
express = require('express')
app = express()
# some libraries we need
_ = require 'lodash'
path = require 'path'
fs = require 'fs'

# All the IIIF tools
iiif = require 'iiif-image'
Informer = iiif.Informer
Extractor = iiif.Extractor
Parser = iiif.ImageRequestParser
InfoJSONCreator = iiif.InfoJSONCreator
Validator = iiif.Validator

# image server functions
image_extraction = require('./image-extraction').image_extraction
resolve_image_path = require('./resolver').resolve_image_path

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
        # If the file does not exist we extract the image again.
        image_extraction(res, url, params, info_cache, image_cache)
      else
        # A good cache hit so we serve the cached image.
        res.sendFile cache_image_path
  else # If the image is not cached run the extraction.

    ###
    We do a quick check whether the parameters of the request are valid
    before trying the extraction. The check here is not able to check
    whether the request is completely valid because we do not have the image
    information yet.
    TODO: In cases where we do have the image information from the
    info_cache we could do a fuller validation of the request (does it result in
    a 0 pixel image? Is the request out of bounds of the image?).
    ###
    validator = new Validator params
    if validator.valid_params()
      # This is where most of the work happens:
      image_extraction(res, url, params, info_cache, image_cache)
    else
      res.status(400).send('400 error')

# TODO: Catch all route that probably ought to return a response code.
app.get '*', (req, res) ->
  res.status(404).send('404 not found')

app.listen 3000, () ->
  console.log('Example IIIF image server listening on port 3000! Visit http://localhost:3000/index.html?id=trumpler14')
