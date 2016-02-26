path = require 'path'
os = require 'os'
config = require 'config'

resolve_base_cache_path = ->
  base_path = config.get('cache.base_path')
  base_path = if base_path == 'tmpdir'
    os.tmpdir()
  else if base_path == 'public'
    path.join __dirname, '/../public'
  else
    base_path

module.exports = resolve_base_cache_path
