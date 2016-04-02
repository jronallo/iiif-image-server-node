#! /usr/bin/env node
;

/*
Script for clearing the cache that tries to retain the images that are specified
in a profile. These may be images important for performance or that are
frequently requested. Uses atime to determine the last accessed time.
 */
var _, bunyan, config, fs, i, image, image_files, len, log, log_file_path, match, now, path, profile_string, profiles, program, regex, resolve_base_cache_path, time_difference_profile_image, time_difference_random_image, yaml;

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

resolve_base_cache_path = require('../lib/resolve-base-cache-path');

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

profiles = _.values(config.get('profile'));

profile_string = profiles.join('$|') + "$";

regex = new RegExp(profile_string);

now = new Date();

time_difference_profile_image = config.get('cache.clean.profile_image');

time_difference_random_image = config.get('cache.clean.random_image');

image_files = find(resolve_base_cache_path()).filter(function(file) {
  return file.match(/.*\.(jpg|png)$/);
});

for (i = 0, len = image_files.length; i < len; i++) {
  image = image_files[i];
  match = image.match(regex);
  if (match) {
    (function(image) {
      return fs.stat(image, function(err, stats) {
        if (now - stats.atime > time_difference_profile_image) {
          rm(image);
          return log.info({
            match: true,
            "delete": true,
            image: image
          }, 'match delete');
        } else {
          return log.info({
            match: true,
            "delete": false,
            image: image
          }, 'match keep');
        }
      });
    })(image);
  } else {
    (function(image) {
      return fs.stat(image, function(err, stats) {
        if (now - stats.atime > time_difference_random_image) {
          log.info({
            match: false,
            "delete": true,
            image: image
          }, 'rand delete');
          return rm(image);
        } else {
          return log.info({
            match: false,
            "delete": false,
            image: image
          }, 'rand keep');
        }
      });
    })(image);
  }
}
