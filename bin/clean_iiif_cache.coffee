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
resolve_base_cache_path = require '../lib/caching/resolve-base-cache-path'

program = require 'commander'
program
  .version '0.0.0'
  .option '-v, --verbose', 'Verbose'
  .parse process.argv

console.log config if program.verbose

if !config.get('profile')
  console.log """

    You must specify a profile in your config file to determine what to clean out!
    See the documentation in config/default.yml for how to create a profile.
  """
  program.outputHelp()
  process.exit()

# TODO: NOT YET IMPLEMENTED
# Find the base path with all the identifier names and for each one call
# the clear_cache_from_profile function with that identifier.
