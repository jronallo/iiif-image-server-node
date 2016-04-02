path = require 'path'
config = require 'config'

# In order to create an IIIF information response we need just a little more
# data from the server than the Informer already provides for the images.
server_info = (req, id) ->
  scheme = if req.connection.encrypted? then 'https' else 'http'
  info_id = path.join req.headers.host, config.get('prefix'), id
  server_info_id = "#{scheme}://#{info_id}"
  full_server_info =
    id: server_info_id
    level: 1
  full_server_info

module.exports = server_info
