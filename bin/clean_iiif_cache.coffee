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
glob = require 'glob'

# loads configuration file
config = require 'config'
# TODO: Use Bunyan logging in verbose mode.

# We need to know the base path used for caching to know where to look for images.
resolve_base_cache_path = require '../lib/caching/resolve-base-cache-path'
clear_cache_from_profile = require('../lib/caching/clear-cache').clear_cache_from_profile

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

search_path = path.join resolve_base_cache_path(), config.get('prefix'), '*'
identifier_paths = glob.sync search_path, {realpath: true}

for identifier_path in identifier_paths
  identifier = identifier_path.split(path.sep).pop()
  clear_cache_from_profile(identifier)
