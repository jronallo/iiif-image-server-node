#! /usr/bin/env node
;

/*
Script for clearing the cache that tries to retain the images that are specified
in a profile. These may be images important for performance or that are
frequently requested. Uses atime to determine the last accessed time.
 */
var _, clear_cache_from_profile, config, fs, glob, i, identifier, identifier_path, identifier_paths, len, path, program, resolve_base_cache_path, search_path, yaml;

require('shelljs/global');

fs = require('fs');

yaml = require('js-yaml');

_ = require('lodash');

path = require('path');

glob = require('glob');

config = require('config');

resolve_base_cache_path = require('../lib/caching/resolve-base-cache-path');

clear_cache_from_profile = require('../lib/caching/clear-cache').clear_cache_from_profile;

program = require('commander');

program.version('0.0.0').option('-v, --verbose', 'Verbose').parse(process.argv);

if (program.verbose) {
  console.log(config);
}

if (!config.get('profile')) {
  console.log("\nYou must specify a profile in your config file to determine what to clean out!\nSee the documentation in config/default.yml for how to create a profile.");
  program.outputHelp();
  process.exit();
}

search_path = path.join(resolve_base_cache_path(), config.get('prefix'), '*');

identifier_paths = glob.sync(search_path, {
  realpath: true
});

for (i = 0, len = identifier_paths.length; i < len; i++) {
  identifier_path = identifier_paths[i];
  identifier = identifier_path.split(path.sep).pop();
  clear_cache_from_profile(identifier);
}
