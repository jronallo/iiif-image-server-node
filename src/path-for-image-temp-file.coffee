###
Storing our imge file cache in the system tmpdir has some advantages.
In some cases utilities like tmpwatch will automatically clear out files which
haven't been accessed in a long time which helps with file cache growth.
Also when the server is rebooted the cache will automatically be cleared.
Of course that is not always what you want, which is just one reason why one
caching solution won't work for every image server.
###

path = require 'path'
os = require 'os'

path_for_image_temp_file = (filename) ->
  path.join os.tmpdir(), filename

module.exports = path_for_image_temp_file
