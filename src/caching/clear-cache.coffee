fs = require 'fs'
path = require 'path'
_ = require 'lodash'
rimraf = require 'rimraf'
async = require 'async'
require 'shelljs/global' # for find
config = require 'config'
resolve_base_cache_path = require './resolve-base-cache-path'
log = require('../index').log

# Setup used by clear_cache_from_profile
# Load the profile and create a regex that can be used to match the profile.
profiles = _.values(config.get('profile'))
profile_string = profiles.join('$|') + "$"
regex = new RegExp profile_string
# Set up dates for comparison.
time_difference_profile_image = config.get('cache.clean.profile_image')
time_difference_random_image = config.get('cache.clean.random_image')

# Completely clear the cache for this identifier.
clear_cache_for_id = (id, callback) ->
  base_path_for_id = path.join resolve_base_cache_path(), id
  rimraf base_path_for_id, (err) ->
    callback(id) if callback?

# Clear the cache for this identifier based on the profile.
clear_cache_from_profile = (id, profile_callback) ->
  # The date we'll be comparing with.
  now = new Date()
  log.info "DATE: #{now}"

  base_path_for_id = path.join resolve_base_cache_path(), id
  fs.stat base_path_for_id, (err, stats) ->
    if err
      profile_callback()
    else
      image_files = find(base_path_for_id)
        .filter (file) ->
          file.match /.*\.(jpg|png)$/

      process_image = (image, process_callback) ->
        # Is there a match with our profile regex?
        match = image.match regex
        # If there is a match with our profile.
        if match
          do (image) -> # Create a closure to do correct work even after another iteration
            # Get file stats
            fs.stat image, (err, stats) ->
              # Check the atime (access time) difference from now to see if it is
              # more than the profile time difference in days. If it is then remove
              # the image since it obviously isn't getting used that much.
              if now - stats.atime > time_difference_profile_image
                rm image
                log.info {match: true, delete: true, image: image}, 'match delete'
              else # Keep the file around which will be the most common case.
                log.info {match: true, delete: false, image: image}, 'match keep'
              process_callback()
        # If there isn't a match
        else
          # TODO: Compare the atime to now. If it has not been
          # accessed for more than about a day, delete the file.
          do (image) -> # Create a closure to do correct work even after another iteration
            fs.stat image, (err, stats) ->
              if now - stats.atime > time_difference_random_image
                log.info {match: false, delete: true, image: image}, 'rand delete'
                rm image
              else
                log.info {match: false, delete: false, image: image}, 'rand keep'
              process_callback()

      # iterate through all the image_files
      async.each image_files, process_image, (err) ->
        profile_callback(id)

exports.clear_cache_for_id = clear_cache_for_id
exports.clear_cache_from_profile = clear_cache_from_profile
