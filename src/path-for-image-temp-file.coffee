path = require 'path'
os = require 'os'

path_for_image_temp_file = (filename) ->
  path.join os.tmpdir(), filename

module.exports = path_for_image_temp_file
