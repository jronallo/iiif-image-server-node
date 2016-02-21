fs = require 'fs-extra'
path = require 'path'

log = require('../src/index').log

# on cleanup remove everything from public between runs
cleanup = ->
  public_path = path.join __dirname, '../public/*'
  fs.remove public_path, (err) ->
    if err
      console.log err

helpers =
  request: require 'supertest'
  app: require('../src/index').app
  test: require 'tape'
  cleanup: cleanup

module.exports = helpers
