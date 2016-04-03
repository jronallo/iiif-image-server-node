#! /usr/bin/env node
;

/*
Script for clearing the cache that tries to retain the images that are specified
in a profile. These may be images important for performance or that are
frequently requested. Uses atime to determine the last accessed time.
 */
var _, bunyan, config, fs, log, log_file_path, path, program, resolve_base_cache_path, yaml;

require('shelljs/global');

fs = require('fs');

yaml = require('js-yaml');

_ = require('lodash');

path = require('path');

bunyan = require('bunyan');

log_file_path = path.join(__dirname, "../log/clean_iiif_cache-" + process.env.NODE_ENV + ".log");

log = bunyan.createLogger({
  name: 'clean_iiif_cache',
  streams: [
    {
      level: 'debug',
      stream: process.stdout
    }, {
      level: 'debug',
      path: log_file_path
    }
  ]
});

config = require('config');

resolve_base_cache_path = require('../lib/caching/resolve-base-cache-path');

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
