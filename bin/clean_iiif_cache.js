#! /usr/bin/env node
;

/*
Script for clearing the cache that tries to retain the images that are specified
in a profile. These may be images important for performance or that are
frequently requested.
Uses atime which
Currently hard codes
 */
var _, config, fs, i, image, image_files, len, match, now, one_day, profile, profile_string, profiles, program, regex, resolve_base_cache_path, time_difference_profile_image, time_difference_random_image, yaml;

require('shelljs/global');

fs = require('fs');

yaml = require('js-yaml');

_ = require('lodash');

config = require('config');

resolve_base_cache_path = require('../lib/resolve-base-cache-path');

program = require('commander');

program.version('0.0.0').usage('-p ../iiif-image/config/profile.yml').option('-p, --profile [value]', 'Directory to image profile document').option('-v, --verbose', 'Verbose').parse(process.argv);

if (program.verbose) {
  console.log(config);
}

profile = yaml.safeLoad(fs.readFileSync(program.profile, 'utf8'));

profiles = _.values(profile);

profile_string = profiles.join('$|') + "$";

regex = new RegExp(profile_string);

now = new Date();

one_day = 1000 * 60 * 60 * 24;

time_difference_profile_image = one_day * 30;

time_difference_random_image = one_day;

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
          if (program.verbose) {
            return console.log("match delete: " + image);
          }
        } else {
          if (program.verbose) {
            return console.log("match keep: " + image);
          }
        }
      });
    })(image);
  } else {
    (function(image) {
      return fs.stat(image, function(err, stats) {
        if (now - stats.atime > time_difference_random_image) {
          if (program.verbose) {
            console.log("old: " + image);
          }
          return rm(image);
        } else {
          if (program.verbose) {
            return console.log("current: " + image);
          }
        }
      });
    })(image);
  }
}
