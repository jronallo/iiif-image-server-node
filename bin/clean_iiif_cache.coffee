`#! /usr/bin/env node
`
###
Script for clearing the cache that tries to retain the images that are specified
in a profile. These may be images important for performance or that are
frequently requested. Uses atime to determine the last accessed time.
###
require 'shelljs/global' # for find
fs = require 'fs'
yaml = require 'js-yaml'
_ = require 'lodash'
path = require 'path'
bunyan = require 'bunyan'

log_file_path = path.join __dirname, "../log/clean_iiif_cache-#{process.env.NODE_ENV}.log"
log = bunyan.createLogger {
  name: 'clean_iiif_cache'
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


# loads configuration file
config = require 'config'
# TODO: Use Bunyan logging in verbose mode.

# We need to know the base path used for caching to know where to look for images.
resolve_base_cache_path = require '../lib/resolve-base-cache-path'

program = require 'commander'
program
  .version '0.0.0'
  .usage '--profile ../iiif-image/config/profile.yml'
  .option '-p, --profile [value]', 'Directory to image profile document'
  .option '-v, --verbose', 'Verbose'
  .parse process.argv

console.log config if program.verbose

if !program.profile
  console.log """

    You must specify a profile YAML document determine what to clean out!
    See the documentation for iiif-image for how to create a profile.
  """
  program.outputHelp()
  process.exit()

# Load the profile and create a regex that can be used to match the profile.
profile = yaml.safeLoad(fs.readFileSync(program.profile, 'utf8'))
profiles =  _.values(profile['urls'])
profile_string = profiles.join('$|') + "$"
regex = new RegExp profile_string

# Set up dates for comparison.
now = new Date()
time_difference_profile_image = config.get('cache.clean.profile_image')
time_difference_random_image = config.get('cache.clean.random_image')

# find all files that are jpg or png but filter out any that match
# the paths we want to stay around as they're frequently used and
# not tiles.
image_files = find(resolve_base_cache_path())
  .filter (file) ->
    file.match /.*\.(jpg|png)$/

# iterate through all the image_files
for image in image_files

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
