config = require 'config'

###
Do a check to see if the image is too large to service the request.
See config/default.yml for more information on the upsize_factor setting.
###
too_big = (params, info) ->
  params.size.w > params.region.w * config.get 'upsize_factor'

exports.too_big = too_big
