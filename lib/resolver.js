// Generated by CoffeeScript 1.10.0

/*
Simple file resolver!
This is how we find the JP2s.
 */

(function() {
  var base_path, config, log, nested_file_path_resolver, pairtree, pairtree_file_path_resolver, path, resolve_directory, resolve_source_image_path, resolver_base_path, sanitize_id;

  path = require('path');

  pairtree = require('pairtree');

  log = require('./index').log;

  config = require('config');

  resolver_base_path = config.get('resolver.base_path');

  sanitize_id = function(id) {
    id.replace(/\./g, '');
    return id;
  };

  base_path = resolver_base_path ? resolver_base_path : path.join(__dirname, "/../images/");

  nested_file_path_resolver = function(id) {
    var first_n, nested_number;
    nested_number = config.get('resolver.nested_number');
    first_n = id.substring(0, nested_number);
    return path.join(base_path, first_n);
  };

  pairtree_file_path_resolver = function(id) {
    var pair_path;
    pair_path = pairtree.path(id);
    return path.join(base_path, pair_path);
  };

  resolve_directory = function(id) {
    var clean_id, type;
    clean_id = sanitize_id(id);
    type = config.get('resolver.type');
    if (type === 'simple') {
      return base_path;
    } else if (type === 'nested') {
      return nested_file_path_resolver(clean_id);
    } else if (type === 'pairtree') {
      return pairtree_file_path_resolver(clean_id);
    }
  };

  resolve_source_image_path = function(id) {
    var clean_id, directory, filename;
    clean_id = sanitize_id(id);
    filename = clean_id + ".jp2";
    directory = resolve_directory(clean_id);
    return path.join(directory, filename);
  };

  exports.resolve_source_image_path = resolve_source_image_path;

  exports.resolve_directory = resolve_directory;

}).call(this);
