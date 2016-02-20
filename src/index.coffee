# The web application frame work
express = require('express')
app = express()
# some libraries we need
_ = require 'lodash'
path = require 'path'
fs = require 'fs'

# configuration from config directory
config = require 'config'
jp2_binary = config.get 'jp2_binary'

# All the IIIF tools we need here
iiif = require 'iiif-image'
Informer = iiif.Informer(jp2_binary)
Parser = iiif.ImageRequestParser
InfoJSONCreator = iiif.InfoJSONCreator
Validator = iiif.Validator

# Image server specific functions
image_extraction = require('./image-extraction').image_extraction
resolve_image_path = require('./resolver').resolve_image_path
path_for_image_cache_file = require './path-for-image-cache-file'

###
Caching
We'll create two different memory caches. One will keep image information
for the life of the process and the other will be to cache images to the file
system for a specified amount of time.
###
NodeCache = require('node-cache')
###
We cache the image information since getting the information from the cache will
be faster than using a child process to return the information. This is
completely in memory of the node instance so does not persist across instances
or restarts.
###
info_cache = new NodeCache()
###
The image_cache is really only used for expiration of an image from
the file system. This works fine for single process applications, but if you
begin to scale out to multiple processes then you will want to use a shared
cache like Memcached.
###
ttl = config.get('cache.image.ttl')
checkperiod = config.get('cache.image.checkperiod')
console.log "Image cache: ttl:#{ttl} checkperiod:#{checkperiod}"
image_cache = new NodeCache stdTTL: ttl, checkperiod: checkperiod
image_cache.on 'del', (key, cached_image_path) ->
  console.log "Image deleted: #{key} #{cached_image_path}"
  fs.unlink cached_image_path, (err) ->
    # Do nothing since we have already achieved our goal to remove the file.
    return

# Serve static cached images from the public directory.
# See the config setting cache.image.base_path for more information.
app.use(express.static('public'))

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

# The actual image server.
# This image server will only accept requests for jpg and png images.
app.get '*.:format(jpg|png)', (req, res) ->
  url = req.url
  ###
  If the image exists just serve that up. This allows cached images
  to be used across instances of the application, but will still not handle
  cache expiration in a unified way. This is why we check for the status of the
  file rather than relying on the memory cache to know whether this is an
  image_cache hit or not.
  ###
  image_temp_file = path_for_image_cache_file(url)
  fs.stat image_temp_file, (err, stats) ->
    if !err
      console.log "cache image hit: #{url} #{image_temp_file}"
      # Since this is a cache hit expand the time to live in the cache.
      image_cache.ttl url, ttl
      res.sendFile image_temp_file
    else
      console.log "cache image miss: #{url} #{image_temp_file}"

      ###
      First we parse the URL to extract all the information we'll need from the
      request to choose the correct image.
      ###
      parser = new Parser url
      params = parser.parse()
      image_path = resolve_image_path(params.identifier)

      ###
      Check to see if the source image exists. If not return a 404.
      ###
      fs.stat image_path, (err, stats) ->
        if err
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
          image_info = info_cache.get params.identifier
          valid_request = if image_info
            validator = new Validator params, image_info
            validity = validator.valid()
            if validity
              console.log "valid with info: #{url}"
            else
              console.log "invalid with info: #{url}"
            validity
          else
            validator = new Validator params
            validity = validator.valid_params()
            if validity
              console.log "valid with params: #{url}"
            else
              console.log "invalid with params: #{url}"
            validity
          # If we have a valid request we try to return an image.
          if valid_request
            # This is where most of the work happens!!!
            image_extraction(res, url, params, info_cache, image_cache)
          else
            console.log "invalid request: #{url}"
            res.status(400).send('400 error')

# Catch all other results and return a response code.
app.get '*', (req, res) ->
  res.status(404).send('404 not found')

app.listen 3001, () ->
  console.log('Example IIIF image server listening on port 3001! Visit http://localhost:3000/index.html?id=trumpler14')
