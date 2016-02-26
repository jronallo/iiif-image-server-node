`#! /usr/bin/env node
`
###
Script for clearing the cache that tries to retain the images that are specified
in a profile. These may be images important for performance or that are
frequently requested.
Uses atime which
Currently hard codes
###
require 'shelljs/global'
fs = require 'fs'
yaml = require 'js-yaml'
_ = require 'lodash'
config = require 'config'

resolve_base_cache_path = require '../lib/resolve-base-cache-path'
program = require 'commander'

program
  .version '0.0.0'
  .usage '-p ../iiif-image/config/profile.yml'
  .option '-p, --profile [value]', 'Directory to image profile document'
  .option '-v, --verbose', 'Verbose'
  .parse process.argv

console.log config if program.verbose

# find all files that are jpg or png but filter out any that match
# the paths we want to stay around as they're frequently used and
# not tiles.

image_files = find(resolve_base_cache_path())
  .filter (file) ->
    file.match /.*\.(jpg|png)$/

profile = yaml.safeLoad(fs.readFileSync(program.profile, 'utf8'))
profiles =  _.values(profile)
#
# profiles = ['/square/300,/0/default.jpg'
#           '/full/600,/0/default.jpg'
#           '/square/75,/0/default.jpg']

profile_string = profiles.join('$|') + "$"

regex = new RegExp profile_string

now = new Date()
one_day=1000*60*60*24
time_difference_profile_image = one_day * 30
time_difference_random_image = one_day

# iterate through all the image_files
for image in image_files
  # Is there a match with our profile regex?
  match = image.match regex
  # If there is a match with our profile.
  if match
    do (image) ->
      # get file stats
      fs.stat image, (err, stats) ->
        # Check the atime (access time) difference from now to see if it is
        # more than 30 days. If it is then remove the image since it
        # obviously isn't getting used that much.
        if now - stats.atime > time_difference_profile_image
          rm image
          console.log "match delete: #{image}" if program.verbose
        else #
          console.log "match keep: #{image}" if program.verbose
  # If there isn't a match
  else
    # TODO: Compare the atime to now. If it has not been
    # accessed for more than about a day, delete the file.
    do (image) ->
      fs.stat image, (err, stats) ->
        if now - stats.atime > time_difference_random_image
          console.log "old: #{image}" if program.verbose
          rm image
        else
          console.log "current: #{image}" if program.verbose
