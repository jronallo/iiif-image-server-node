# The web application frame work
express = require('express')
app = express()

# some libraries we need
path = require 'path' # Used to join paths for static assets.
fs = require 'fs' # Used to unlink images expired from the cache.

# Configuration from config directory.
config = require 'config'

###
Logging
Currently we have one logger that logs to stdout and to a file in the log
directory.
###
bunyan = require 'bunyan'
###
In order to have environment specific log files you will need to set NODE_ENV
in your environment. You can see examples of how this is done in the scripts
in package.json.
###
log_file_path = path.join __dirname, "../log/iiif-#{process.env.NODE_ENV}.log"
log = bunyan.createLogger {
  name: 'iiif'
  streams: [
    {
      level: 'debug',
      stream: process.stdout
    },
    {
      level: 'debug'
      path: log_file_path
    }
  ]
}

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
info_cache_ttl = config.get('cache.info.ttl')
info_cache_checkperiod = config.get('cache.info.checkperiod')
log.info {ttl: info_cache_ttl, checkperiod: info_cache_checkperiod}, 'info_cache settings'
info_cache = new NodeCache stdTTL: info_cache_ttl, checkperiod: info_cache_checkperiod
###
The image_cache is really only used for expiration of an image from
the file system. This works fine for single process applications, but if you
begin to scale out to multiple processes then you will want to use a shared
cache like Memcached.
###
image_cache_ttl = config.get('cache.image.ttl')
image_cache_checkperiod = config.get('cache.image.checkperiod')
log.info {ttl: image_cache_ttl, checkperiod: image_cache_checkperiod}, 'image_cache settings'

# Create the image_cache
image_cache = new NodeCache stdTTL: image_cache_ttl, checkperiod: image_cache_checkperiod

###
When an image gets deleted or expired from the cache unlink the cached file.
###
image_cache.on 'del', (key, cached_image_path) ->
  log.info {cache: 'image', op: 'del', key: key, img: cached_image_path}, "image deleted"
  fs.unlink cached_image_path, (err) ->
    # Do nothing since we have already achieved our goal to remove the file.
    return

###
Exports
###
exports.log = log
exports.image_cache = image_cache
exports.info_cache = info_cache

###
Image server specific functions.
Note that the order of the code here is important!
These local modules must be required _after_ the Exports section of this code
so that they are available when we need them in these modules. Otherwise
log etc. will be undefined within the modules.
###
# TODO: Allow for selecting a custom implementation of info_json_response
info_json_response = require './info-json-response'
# TODO: Allow for selecting a custom implementation for image response
image_response = require './image-response'
resolve_image_path = require('./resolver').resolve_image_path

###
Static assets in this case means cached image files when the
config.cache.base_path value is 'public'. Otherwise the image server
has no need for serving up static assets. The
###
if config.get('cache.base_path') == 'public'
  log.info 'Use Express to serve static assets'
  app.use(express.static('public'))

# Configuration allows the openseadragon viewer to be turned off.
if config.get('viewer')
  # Serve a web page for an openseadragon viewer.
  # http://localhost:3000/index.html?id=trumpler14
  app.get '/viewer/:id/', (req, res) ->
    log.info {route: 'viewer', url: req.url, ip: req.ip}
    image_path = resolve_image_path(req.params.id)
    fs.stat image_path, (err, stats) ->
      if err
        log.info {res: '404', url: req.url, ip: req.ip}, '404'
        res.status(404).send('404')
      else
        log.info {res: 'viewer', url: req.url, ip: req.ip}, '400'
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
  log.info {route: 'info.json', url: req.url, ip: req.ip}
  # Set CORS header
  if config.get 'cors'
    res.header "Access-Control-Allow-Origin", config.get 'cors'
  info_json_response(req, res, info_cache)

# The actual image server.
# This image server will only accept requests for jpg and png images.
app.get '*default.:format(jpg|png)', (req, res) ->
  log.info {route: 'image', url: req.url, ip: req.ip}
  image_response(req, res, info_cache, image_cache)

# Catch all other requests. In some cases this will be a
# request with an image identifier in which case we
# redirect to the info.json.
app.get '*', (req, res) ->
  log.info {route: '*', url: req.url, ip: req.ip}
  # If the first part of the path is an identifier and there
  # are no other path segements then we redirect to the
  # info.json response.
  url = req.url
  url_parts = url.split('/')
  possible_image_identifier = url_parts[0]
  possible_image_path = resolve_image_path possible_image_identifier
  fs.stat possible_image_path, (err, stats) ->
    if err
      log.info {res: '400', url: url, ip: req.ip}, '400'
      # Catch all other results and return a response code.
      res.status(400).send('400 not found')
    else
      log.info {res: '303', url: url, ip: req.ip}, '303'
      res.redirect '303', "/#{possible_image_identifier}/info.json"

# if require.main == module
unless process.env.NODE_ENV == 'test'
  port = process.env.PORT || 3001
  app.listen port, () ->
    console.log("IIIF image server listening on port #{port}! Visit http://localhost:#{port}/viewer/trumpler14")

exports.app = app
