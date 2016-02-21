# The web application frame work
express = require('express')
app = express()

# some libraries we need
path = require 'path' # Used to join paths for static assets.
fs = require 'fs' # Used to unlink images expired from the cache.

# Configuration from config directory.
config = require 'config'

# Image server specific functions:
# TODO: Allow for selecting a custom implementation of info_json_response
info_json_response = require './info-json-response'
# TODO: Allow for selecting a custom implementation for image response
image_response = require './image-response'

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

# Configuration allows the openseadragon viewer to be turned off.
if config.get('viewer')
  # Serve a web page for an openseadragon viewer.
  # http://localhost:3000/index.html?id=trumpler14
  app.get '/viewer/:id/', (req, res) ->
    index = path.join __dirname, "/../app/index.html"
    res.setHeader('Content-Type', 'text/html')
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
  info_json_response(req, res, info_cache)

# The actual image server.
# This image server will only accept requests for jpg and png images.
app.get '*.:format(jpg|png)', (req, res) ->
  image_response(req, res, info_cache, image_cache)

# Catch all other results and return a response code.
app.get '*', (req, res) ->
  res.status(404).send('404 not found')

app.listen 3001, () ->
  console.log('Example IIIF image server listening on port 3001! Visit http://localhost:3000/viewer/trumpler14')
